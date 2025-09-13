#!/bin/bash

# Script to generate terraform.tfvars for VPC module
# Automatically detects user's public IP and generates appropriate subnet configurations

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_FILE="$PROJECT_ROOT/iac-vpc/terraform.tfvars.template"
OUTPUT_FILE="$PROJECT_ROOT/iac-vpc/terraform.tfvars"

# Default values
AWS_PROFILE=""
AWS_REGION=""
VPC_CIDR="10.100.0.0/16"
VPC_NAME="ai-dev-vpc"
ENVIRONMENT="development"
ENABLE_NAT_GATEWAY="false"
OVERWRITE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Usage: $0 -p|--profile <profile> -r|--region <region> [OPTIONS]

Generate terraform.tfvars file for VPC module with sensible defaults.

Required arguments:
  -p, --profile <profile>    AWS CLI profile name
  -r, --region <region>      AWS region (e.g., us-east-1, us-west-2)

Optional arguments:
  -c, --cidr <cidr>          VPC CIDR block (default: 10.100.0.0/16)
  -n, --name <name>          VPC name (default: ai-dev-vpc)
  -e, --environment <env>    Environment name (default: development)
  --enable-nat-gateway       Enable NAT Gateway (default: false, saves ~\$45/month)
  -o, --output <file>        Output file path (default: iac-vpc/terraform.tfvars)
  -w, --overwrite           Overwrite existing file without prompting
  -h, --help                Show this help message

Examples:
  # Basic usage
  $0 -p corp-dev -r us-east-1

  # Custom VPC CIDR with NAT Gateway
  $0 -p corp-prod -r us-west-2 -c 10.200.0.0/16 --enable-nat-gateway

  # Development environment with custom name
  $0 -p corp-dev -r us-east-1 -n my-ai-vpc -e development

Note: Script will automatically:
  - Calculate appropriate subnet CIDRs based on VPC CIDR
  - Select the first available AZ in the region
EOF
}

# Log functions
log_info() {
    echo -e "${BLUE}$1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}" >&2
}

log_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}" >&2
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--profile)
                AWS_PROFILE="$2"
                shift 2
                ;;
            -r|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            -c|--cidr)
                VPC_CIDR="$2"
                shift 2
                ;;
            -n|--name)
                VPC_NAME="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --enable-nat-gateway)
                ENABLE_NAT_GATEWAY="true"
                shift
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -w|--overwrite)
                OVERWRITE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$AWS_PROFILE" ]]; then
        log_error "AWS profile is required. Use -p|--profile <profile-name>"
        usage
        exit 1
    fi

    if [[ -z "$AWS_REGION" ]]; then
        log_error "AWS region is required. Use -r|--region <region-name>"
        usage
        exit 1
    fi
}

# Check AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
}

# Verify AWS credentials
verify_aws_credentials() {
    log_info "Verifying AWS credentials for profile: $AWS_PROFILE"

    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" &> /dev/null; then
        log_warning "AWS credentials not valid. Attempting SSO login..."

        if ! aws sso login --profile "$AWS_PROFILE"; then
            log_error "Failed to authenticate with AWS SSO"
            exit 1
        fi

        if ! aws sts get-caller-identity --profile "$AWS_PROFILE" --region "$AWS_REGION" &> /dev/null; then
            log_error "Authentication failed even after SSO login"
            exit 1
        fi
    fi

    log_success "AWS credentials verified"
}

# Get first available AZ in region
get_availability_zone() {
    log_info "Getting availability zones for region: $AWS_REGION"

    local az
    az=$(aws ec2 describe-availability-zones \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --filters "Name=state,Values=available" \
        --query 'AvailabilityZones[0].ZoneName' \
        --output text 2>/dev/null)

    if [[ -z "$az" || "$az" == "None" ]]; then
        # Fallback to common pattern
        az="${AWS_REGION}a"
        log_warning "Could not detect AZ, using default: $az"
    else
        log_success "Selected availability zone: $az"
    fi

    echo "$az"
}


# Calculate subnet CIDRs based on VPC CIDR
calculate_subnet_cidrs() {
    local vpc_cidr="$1"

    # Extract network and prefix from VPC CIDR
    local network prefix
    network=$(echo "$vpc_cidr" | cut -d'/' -f1)
    prefix=$(echo "$vpc_cidr" | cut -d'/' -f2)

    # Validate VPC prefix (must be /24 or smaller to fit two /24 subnets)
    if [[ "$prefix" -gt 23 ]]; then
        log_error "VPC CIDR prefix must be /23 or smaller (got /$prefix)"
        log_error "Cannot create two /24 subnets within a /$prefix network"
        exit 1
    fi

    # Calculate subnet prefix (we use /24 subnets)
    local subnet_prefix=24

    # Extract octets from VPC network
    local oct1 oct2 oct3 oct4
    IFS='.' read -r oct1 oct2 oct3 oct4 <<< "$network"

    # Calculate subnet CIDRs based on VPC size
    if [[ "$prefix" -eq 16 ]]; then
        # For /16: use x.x.1.0/24 and x.x.10.0/24
        PUBLIC_SUBNET_CIDR="${oct1}.${oct2}.1.0/${subnet_prefix}"
        PRIVATE_SUBNET_CIDR="${oct1}.${oct2}.10.0/${subnet_prefix}"
    elif [[ "$prefix" -le 23 ]]; then
        # For /23 and smaller: use first two available /24 blocks
        # This works for /22, /21, /20, etc.
        PUBLIC_SUBNET_CIDR="${oct1}.${oct2}.${oct3}.0/${subnet_prefix}"

        # Calculate next /24 block for private subnet
        local next_oct3=$((oct3 + 1))
        PRIVATE_SUBNET_CIDR="${oct1}.${oct2}.${next_oct3}.0/${subnet_prefix}"
    fi

    log_info "Calculated subnet CIDRs from VPC $vpc_cidr:"
    log_info "  Public:  $PUBLIC_SUBNET_CIDR"
    log_info "  Private: $PRIVATE_SUBNET_CIDR"
}

# Check if template file exists
check_template() {
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Template file not found: $TEMPLATE_FILE"
        exit 1
    fi
}

# Check if output file exists and handle overwrite
check_output_file() {
    if [[ -f "$OUTPUT_FILE" ]] && [[ "$OVERWRITE" != "true" ]]; then
        log_warning "Output file already exists: $OUTPUT_FILE"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted. Use -w|--overwrite to skip this prompt."
            exit 0
        fi
    fi
}

# Generate terraform.tfvars from template
generate_tfvars() {
    log_info "Generating terraform.tfvars file..."

    # Get availability zone
    local availability_zone
    availability_zone=$(get_availability_zone)

    # Calculate subnet CIDRs
    calculate_subnet_cidrs "$VPC_CIDR"

    # Get current timestamp
    local created_at
    created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Copy template and replace placeholders
    cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

    # Replace placeholders
    sed -i.bak \
        -e "s|{{VPC_NAME}}|$VPC_NAME|g" \
        -e "s|{{VPC_CIDR}}|$VPC_CIDR|g" \
        -e "s|{{ENVIRONMENT}}|$ENVIRONMENT|g" \
        -e "s|{{AWS_REGION}}|$AWS_REGION|g" \
        -e "s|{{AWS_PROFILE}}|$AWS_PROFILE|g" \
        -e "s|{{AVAILABILITY_ZONE}}|$availability_zone|g" \
        -e "s|{{PUBLIC_SUBNET_CIDR}}|$PUBLIC_SUBNET_CIDR|g" \
        -e "s|{{PRIVATE_SUBNET_CIDR}}|$PRIVATE_SUBNET_CIDR|g" \
        -e "s|{{ENABLE_NAT_GATEWAY}}|$ENABLE_NAT_GATEWAY|g" \
        -e "s|{{CREATED_AT}}|$created_at|g" \
        "$OUTPUT_FILE"

    # Remove backup file
    rm -f "${OUTPUT_FILE}.bak"

    log_success "terraform.tfvars generated successfully!"
}

# Display summary
display_summary() {
    echo ""
    echo -e "${GREEN}=== Configuration Summary ===${NC}"
    echo -e "${BLUE}Output file:${NC} $OUTPUT_FILE"
    echo -e "${BLUE}AWS Profile:${NC} $AWS_PROFILE"
    echo -e "${BLUE}AWS Region:${NC} $AWS_REGION"
    echo -e "${BLUE}VPC Name:${NC} $VPC_NAME"
    echo -e "${BLUE}VPC CIDR:${NC} $VPC_CIDR"
    echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
    echo -e "${BLUE}NAT Gateway:${NC} $ENABLE_NAT_GATEWAY"
    echo ""

    if [[ "$ENABLE_NAT_GATEWAY" == "false" ]]; then
        echo -e "${YELLOW}💰 Cost Savings: NAT Gateway disabled (saves ~\$45/month)${NC}"
    else
        echo -e "${YELLOW}💸 Cost Warning: NAT Gateway enabled (~\$45/month plus data charges)${NC}"
    fi

    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "  1. Review the generated file: cat $OUTPUT_FILE"
    echo "  2. Initialize Terraform: cd $PROJECT_ROOT/iac-vpc && terraform init"
    echo "  3. Plan the deployment: terraform plan"
    echo "  4. Apply the configuration: terraform apply"
    echo ""
}

# Main function
main() {
    log_info "VPC terraform.tfvars Generator"

    # Parse arguments
    parse_args "$@"

    # Check prerequisites
    check_aws_cli
    check_template

    # Verify AWS credentials
    verify_aws_credentials

    # Check output file
    check_output_file

    # Generate tfvars file
    generate_tfvars

    # Display summary
    display_summary
}

# Run main function
main "$@"