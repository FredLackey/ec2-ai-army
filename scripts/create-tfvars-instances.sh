#!/bin/bash

# Script to generate terraform.tfvars for Instances module
# Configures EC2 instances with sensible defaults for AI workloads

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATE_FILE="$PROJECT_ROOT/iac-instances/terraform.tfvars.template"
OUTPUT_FILE="$PROJECT_ROOT/iac-instances/terraform.tfvars"

# Required values (must be provided)
AWS_PROFILE=""
AWS_REGION=""
VPC_ID=""
SUBNET_ID=""
INSTANCE_COUNT=""

# Optional values with defaults
AMI_ID=""
INSTANCE_TYPE="t3.micro"
INSTANCE_NAME_PREFIX="ai-army"
ENVIRONMENT="development"
ENABLE_MONITORING="false"
KEY_NAME=""
ROOT_VOLUME_SIZE="10"
MANUAL_IP=""
ROOT_VOLUME_TYPE="gp3"
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
Usage: $0 -p|--profile <profile> -r|--region <region> -v|--vpc-id <vpc-id> -s|--subnet-id <subnet-id> -c|--count <count> [OPTIONS]

Generate terraform.tfvars file for EC2 Instances module with sensible defaults for AI workloads.

Required arguments:
  -p, --profile <profile>      AWS CLI profile name
  -r, --region <region>        AWS region (e.g., us-east-1, us-west-2)
  -v, --vpc-id <vpc-id>        VPC ID where instances will be deployed
  -s, --subnet-id <subnet-id>  Subnet ID where instances will be deployed
  -c, --count <count>          Number of instances to create

Optional arguments:
  -a, --ami-id <ami-id>        Ubuntu AMI ID (if not provided, latest Ubuntu 22.04 will be used)
  -t, --type <type>            Instance type (default: t3.micro)
  -n, --name <prefix>          Instance name prefix (default: ai-army)
  -e, --environment <env>      Environment name (default: development)
  -k, --key-name <key>         SSH key pair name (default: ai-army-<region>)
  -i, --ip <ip>                Your public IP in CIDR format (e.g., 1.2.3.4/32)
                               If not provided, will attempt auto-detection for SSH access
  --volume-size <size>         Root volume size in GB (default: 10)
  --volume-type <type>         Root volume type (default: gp3)
  --enable-monitoring          Enable detailed CloudWatch monitoring (default: false, costs extra)
  -o, --output <file>          Output file path (default: iac-instances/terraform.tfvars)
  -w, --overwrite              Overwrite existing file without prompting
  -h, --help                   Show this help message

Examples:
  # Basic usage with 3 instances
  $0 -p corp-dev -r us-east-1 -v vpc-12345 -s subnet-67890 -c 3

  # Specify custom AMI and instance type
  $0 -p corp-dev -r us-east-1 -v vpc-12345 -s subnet-67890 -c 5 -a ami-0c55b159cbfafe1f0 -t t3.large

  # Production setup with monitoring and larger volumes
  $0 -p corp-prod -r us-west-2 -v vpc-12345 -s subnet-67890 -c 10 -e production --volume-size 100 --enable-monitoring

  # Use custom SSH key
  $0 -p corp-dev -r us-east-1 -v vpc-12345 -s subnet-67890 -c 2 -k my-ssh-key

  # Manually specify your IP for SSH access
  $0 -p corp-dev -r us-east-1 -v vpc-12345 -s subnet-67890 -c 3 -i 203.0.113.45/32

Note:
  - If no AMI is specified, the script will find the latest Ubuntu 22.04 LTS AMI
  - SSH keys will be generated if they don't exist (stored in ~/.ssh/)
  - Your public IP will be auto-detected for SSH access (or specify with -i)
  - A new security group will be created with SSH access from trusted IPs
  - Instance costs vary by type and region - check AWS pricing
EOF
}

# Log functions
log_info() {
    echo -e "${BLUE}$1${NC}" >&2
}

log_success() {
    echo -e "${GREEN} $1${NC}" >&2
}

log_error() {
    echo -e "${RED} $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}� $1${NC}" >&2
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
            -v|--vpc-id)
                VPC_ID="$2"
                shift 2
                ;;
            -s|--subnet-id)
                SUBNET_ID="$2"
                shift 2
                ;;
            -c|--count)
                INSTANCE_COUNT="$2"
                shift 2
                ;;
            -a|--ami-id)
                AMI_ID="$2"
                shift 2
                ;;
            -t|--type)
                INSTANCE_TYPE="$2"
                shift 2
                ;;
            -n|--name)
                INSTANCE_NAME_PREFIX="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -k|--key-name)
                KEY_NAME="$2"
                shift 2
                ;;
            -i|--ip)
                MANUAL_IP="$2"
                shift 2
                ;;
            --volume-size)
                ROOT_VOLUME_SIZE="$2"
                shift 2
                ;;
            --volume-type)
                ROOT_VOLUME_TYPE="$2"
                shift 2
                ;;
            --enable-monitoring)
                ENABLE_MONITORING="true"
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

    if [[ -z "$VPC_ID" ]]; then
        log_error "VPC ID is required. Use -v|--vpc-id <vpc-id>"
        usage
        exit 1
    fi

    if [[ -z "$SUBNET_ID" ]]; then
        log_error "Subnet ID is required. Use -s|--subnet-id <subnet-id>"
        usage
        exit 1
    fi

    if [[ -z "$INSTANCE_COUNT" ]]; then
        log_error "Instance count is required. Use -c|--count <count>"
        usage
        exit 1
    fi

    # Validate instance count is a positive number
    if ! [[ "$INSTANCE_COUNT" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Instance count must be a positive integer"
        exit 1
    fi

    # Validate volume size is a positive number
    if ! [[ "$ROOT_VOLUME_SIZE" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Volume size must be a positive integer"
        exit 1
    fi

    # Set default key name if not provided
    if [[ -z "$KEY_NAME" ]]; then
        KEY_NAME="ai-army-${AWS_REGION}"
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

# Verify VPC exists
verify_vpc() {
    log_info "Verifying VPC: $VPC_ID"

    local vpc_info
    vpc_info=$(aws ec2 describe-vpcs \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --vpc-ids "$VPC_ID" \
        --query 'Vpcs[0].{CidrBlock:CidrBlock,State:State}' \
        --output json 2>/dev/null || echo "null")

    if [[ "$vpc_info" == "null" ]]; then
        log_error "VPC $VPC_ID not found in region $AWS_REGION"
        exit 1
    fi

    local vpc_state
    vpc_state=$(echo "$vpc_info" | jq -r '.State')

    if [[ "$vpc_state" != "available" ]]; then
        log_error "VPC $VPC_ID is not in available state (current: $vpc_state)"
        exit 1
    fi

    local vpc_cidr
    vpc_cidr=$(echo "$vpc_info" | jq -r '.CidrBlock')
    log_success "VPC verified: $VPC_ID ($vpc_cidr)"
}

# Verify subnet exists and is in the VPC
verify_subnet() {
    log_info "Verifying subnet: $SUBNET_ID"

    local subnet_info
    subnet_info=$(aws ec2 describe-subnets \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --subnet-ids "$SUBNET_ID" \
        --query 'Subnets[0].{VpcId:VpcId,CidrBlock:CidrBlock,AZ:AvailabilityZone,State:State}' \
        --output json 2>/dev/null || echo "null")

    if [[ "$subnet_info" == "null" ]]; then
        log_error "Subnet $SUBNET_ID not found in region $AWS_REGION"
        exit 1
    fi

    local subnet_vpc
    subnet_vpc=$(echo "$subnet_info" | jq -r '.VpcId')

    if [[ "$subnet_vpc" != "$VPC_ID" ]]; then
        log_error "Subnet $SUBNET_ID is not in VPC $VPC_ID (found in: $subnet_vpc)"
        exit 1
    fi

    local subnet_state
    subnet_state=$(echo "$subnet_info" | jq -r '.State')

    if [[ "$subnet_state" != "available" ]]; then
        log_error "Subnet $SUBNET_ID is not in available state (current: $subnet_state)"
        exit 1
    fi

    local subnet_cidr subnet_az
    subnet_cidr=$(echo "$subnet_info" | jq -r '.CidrBlock')
    subnet_az=$(echo "$subnet_info" | jq -r '.AZ')

    log_success "Subnet verified: $SUBNET_ID ($subnet_cidr in $subnet_az)"
}

# Find latest Ubuntu AMI if not provided
find_ubuntu_ami() {
    if [[ -n "$AMI_ID" ]]; then
        log_info "Using provided AMI: $AMI_ID"

        # Verify the AMI exists
        local ami_info
        ami_info=$(aws ec2 describe-images \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" \
            --image-ids "$AMI_ID" \
            --query 'Images[0].{Name:Name,State:State,Architecture:Architecture}' \
            --output json 2>/dev/null || echo "null")

        if [[ "$ami_info" == "null" ]]; then
            log_error "AMI $AMI_ID not found in region $AWS_REGION"
            exit 1
        fi

        local ami_name
        ami_name=$(echo "$ami_info" | jq -r '.Name')
        log_success "AMI verified: $ami_name"
        return
    fi

    log_info "Finding latest Ubuntu 22.04 LTS AMI..."

    # Use the find-ubuntu-amis.sh script if available
    local find_script="$SCRIPT_DIR/find-ubuntu-amis.sh"

    if [[ -x "$find_script" ]]; then
        # Run the script and capture the latest AMI
        AMI_ID=$("$find_script" -p "$AWS_PROFILE" -r "$AWS_REGION" -v 22.04 -l 2>/dev/null | grep -oE 'ami-[a-f0-9]+' | head -1)

        if [[ -n "$AMI_ID" ]]; then
            log_success "Found latest Ubuntu 22.04 AMI: $AMI_ID"
            return
        fi
    fi

    # Fallback: directly query for Ubuntu AMI
    AMI_ID=$(aws ec2 describe-images \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --owners 099720109477 \
        --filters \
            "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
            "Name=architecture,Values=x86_64" \
            "Name=virtualization-type,Values=hvm" \
        --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
        --output text 2>/dev/null)

    if [[ -z "$AMI_ID" || "$AMI_ID" == "None" ]]; then
        log_error "Could not find Ubuntu 22.04 AMI in region $AWS_REGION"
        log_error "Please specify an AMI ID manually with -a|--ami-id"
        exit 1
    fi

    log_success "Found latest Ubuntu 22.04 AMI: $AMI_ID"
}

# Check or create SSH key pair
check_ssh_key() {
    log_info "Checking SSH key pair: $KEY_NAME"

    # Check if key exists in AWS
    local key_exists
    key_exists=$(aws ec2 describe-key-pairs \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --key-names "$KEY_NAME" \
        --query 'KeyPairs[0].KeyName' \
        --output text 2>/dev/null || echo "")

    if [[ -n "$key_exists" ]]; then
        log_success "SSH key pair already exists in AWS: $KEY_NAME"

        # Check if we have the private key locally
        local private_key_path="$HOME/.ssh/${KEY_NAME}.pem"
        if [[ ! -f "$private_key_path" ]]; then
            log_warning "Private key not found locally at: $private_key_path"
            log_warning "Make sure you have the private key to access instances"
        fi
        return
    fi

    # Key doesn't exist, create it
    log_info "Creating new SSH key pair: $KEY_NAME"

    local private_key_path="$HOME/.ssh/${KEY_NAME}.pem"

    # Create the key pair
    aws ec2 create-key-pair \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION" \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "$private_key_path"

    if [[ ! -f "$private_key_path" ]]; then
        log_error "Failed to create SSH key pair"
        exit 1
    fi

    # Set proper permissions
    chmod 600 "$private_key_path"

    log_success "SSH key pair created and saved to: $private_key_path"
    log_info "Keep this file safe - it's required to access your instances"
}

# Get or detect public IP address
get_trusted_ip() {
    # If manual IP was provided, validate and use it
    if [[ -n "$MANUAL_IP" ]]; then
        # Validate IP format (basic check for x.x.x.x/32 or x.x.x.x)
        if [[ "$MANUAL_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/32)?$ ]]; then
            # Add /32 if not present
            if [[ ! "$MANUAL_IP" =~ /32$ ]]; then
                MANUAL_IP="${MANUAL_IP}/32"
            fi
            log_success "Using manually provided IP: $MANUAL_IP"
            echo "$MANUAL_IP"
            return 0
        else
            log_error "Invalid IP format: $MANUAL_IP"
            log_error "Expected format: x.x.x.x or x.x.x.x/32"
            exit 1
        fi
    fi

    # Try to auto-detect IP
    log_info "Detecting your public IP address for SSH access..."

    local public_ip=""

    # Try multiple services to be resilient
    local services=(
        "https://checkip.amazonaws.com"
        "https://ipinfo.io/ip"
        "https://api.ipify.org"
        "https://ifconfig.me"
    )

    for service in "${services[@]}"; do
        public_ip=$(curl -s --max-time 5 "$service" 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)

        if [[ -n "$public_ip" ]]; then
            log_success "Auto-detected public IP: $public_ip"
            echo "${public_ip}/32"
            return 0
        fi
    done

    # Failed to detect - this is now a fatal error
    log_error "Failed to detect public IP address!"
    log_error "Your public IP is required for secure SSH access configuration."
    log_error ""
    log_error "Please manually specify your IP using the -i|--ip option:"
    log_error "  $0 -p $AWS_PROFILE -r $AWS_REGION -v $VPC_ID -s $SUBNET_ID -c $INSTANCE_COUNT -i YOUR_IP_ADDRESS/32"
    log_error ""
    log_error "You can find your public IP at: https://whatismyipaddress.com"
    exit 1
}



# Check template file exists
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

    # Get trusted IP (manual or auto-detected) for SSH access
    local trusted_ip
    trusted_ip=$(get_trusted_ip)
    TRUSTED_IP_DISPLAY="$trusted_ip"  # Save for summary display

    # Get current timestamp
    local created_at
    created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Copy template and replace placeholders
    cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

    # Replace placeholders
    sed -i.bak \
        -e "s|{{AWS_REGION}}|$AWS_REGION|g" \
        -e "s|{{AWS_PROFILE}}|$AWS_PROFILE|g" \
        -e "s|{{VPC_ID}}|$VPC_ID|g" \
        -e "s|{{SUBNET_ID}}|$SUBNET_ID|g" \
        -e "s|{{INSTANCE_COUNT}}|$INSTANCE_COUNT|g" \
        -e "s|{{INSTANCE_TYPE}}|$INSTANCE_TYPE|g" \
        -e "s|{{AMI_ID}}|$AMI_ID|g" \
        -e "s|{{INSTANCE_NAME_PREFIX}}|$INSTANCE_NAME_PREFIX|g" \
        -e "s|{{ENVIRONMENT}}|$ENVIRONMENT|g" \
        -e "s|{{ENABLE_MONITORING}}|$ENABLE_MONITORING|g" \
        -e "s|{{TRUSTED_IP}}|$trusted_ip|g" \
        -e "s|{{ROOT_VOLUME_SIZE}}|$ROOT_VOLUME_SIZE|g" \
        -e "s|{{ROOT_VOLUME_TYPE}}|$ROOT_VOLUME_TYPE|g" \
        "$OUTPUT_FILE"

    # Remove backup file
    rm -f "${OUTPUT_FILE}.bak"

    log_success "terraform.tfvars generated successfully!"
}

# Calculate estimated costs
calculate_costs() {
    # Basic hourly costs (us-east-1 prices, approximate)
    local hourly_cost=0

    case "$INSTANCE_TYPE" in
        t3.micro)   hourly_cost=0.0104 ;;
        t3.small)   hourly_cost=0.0208 ;;
        t3.medium)  hourly_cost=0.0416 ;;
        t3.large)   hourly_cost=0.0832 ;;
        t3.xlarge)  hourly_cost=0.1664 ;;
        t3.2xlarge) hourly_cost=0.3328 ;;
        *)          hourly_cost=0.05 ;;  # Default estimate
    esac

    local monthly_instance_cost=$(awk "BEGIN {printf \"%.2f\", $hourly_cost * 730 * $INSTANCE_COUNT}")
    local monthly_storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.08 * $ROOT_VOLUME_SIZE * $INSTANCE_COUNT}")
    local monthly_monitoring_cost=0

    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        monthly_monitoring_cost=$(awk "BEGIN {printf \"%.2f\", 2.10 * $INSTANCE_COUNT}")
    fi

    local total_monthly=$(awk "BEGIN {printf \"%.2f\", $monthly_instance_cost + $monthly_storage_cost + $monthly_monitoring_cost}")

    echo -e "${YELLOW}=� Estimated Monthly Costs (us-east-1 prices):${NC}"
    echo -e "   Instances ($INSTANCE_COUNT x $INSTANCE_TYPE): \$${monthly_instance_cost}/month"
    echo -e "   Storage ($INSTANCE_COUNT x ${ROOT_VOLUME_SIZE}GB $ROOT_VOLUME_TYPE): \$${monthly_storage_cost}/month"

    if [[ "$ENABLE_MONITORING" == "true" ]]; then
        echo -e "   CloudWatch Monitoring: \$${monthly_monitoring_cost}/month"
    fi

    echo -e "   ${YELLOW}Total Estimated: \$${total_monthly}/month${NC}"
    echo ""
    echo -e "${BLUE}=� Cost Optimization Tips:${NC}"
    echo "   - Use Spot Instances for up to 90% savings"
    echo "   - Stop instances when not in use"
    echo "   - Consider Reserved Instances for long-term use"
}

# Display summary
display_summary() {
    echo ""
    echo -e "${GREEN}=== Configuration Summary ===${NC}"
    echo -e "${BLUE}Output file:${NC} $OUTPUT_FILE"
    echo -e "${BLUE}AWS Profile:${NC} $AWS_PROFILE"
    echo -e "${BLUE}AWS Region:${NC} $AWS_REGION"
    echo -e "${BLUE}VPC ID:${NC} $VPC_ID"
    echo -e "${BLUE}Subnet ID:${NC} $SUBNET_ID"
    echo -e "${BLUE}Instance Count:${NC} $INSTANCE_COUNT"
    echo -e "${BLUE}Instance Type:${NC} $INSTANCE_TYPE"
    echo -e "${BLUE}AMI ID:${NC} $AMI_ID"
    echo -e "${BLUE}Instance Name Prefix:${NC} $INSTANCE_NAME_PREFIX"
    echo -e "${BLUE}Environment:${NC} $ENVIRONMENT"
    echo -e "${BLUE}SSH Key:${NC} $KEY_NAME"
    echo -e "${BLUE}SSH Access IP:${NC} $TRUSTED_IP_DISPLAY"
    echo -e "${BLUE}Monitoring:${NC} $ENABLE_MONITORING"
    echo -e "${BLUE}Root Volume:${NC} ${ROOT_VOLUME_SIZE}GB $ROOT_VOLUME_TYPE"
    echo ""

    # Show cost estimates
    calculate_costs

    # SSH connection info
    echo -e "${GREEN}= SSH Access:${NC}"
    echo "   Key file: ~/.ssh/${KEY_NAME}.pem"
    echo "   Connect: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@<instance-ip>"
    echo "   Allowed from: $TRUSTED_IP_DISPLAY"
    echo "   Note: You can add more IPs to the trusted_entities array in terraform.tfvars"
    echo ""

    echo -e "${GREEN}Next steps:${NC}"
    echo "  1. Review the generated file: cat $OUTPUT_FILE"
    echo "  2. Initialize Terraform: cd $PROJECT_ROOT/iac-instances && terraform init"
    echo "  3. Plan the deployment: terraform plan"
    echo "  4. Apply the configuration: terraform apply"
    echo ""

    if [[ "$INSTANCE_COUNT" -gt 10 ]]; then
        echo -e "${YELLOW}�  Warning: You're creating $INSTANCE_COUNT instances.${NC}"
        echo -e "${YELLOW}   Make sure this is intentional to avoid unexpected costs.${NC}"
        echo ""
    fi
}

# Main function
main() {
    log_info "EC2 Instances terraform.tfvars Generator"

    # Parse arguments
    parse_args "$@"

    # Check prerequisites
    check_aws_cli
    check_template

    # Verify AWS credentials
    verify_aws_credentials

    # Verify VPC and subnet
    verify_vpc
    verify_subnet

    # Find or verify AMI
    find_ubuntu_ami

    # Check/create SSH key
    check_ssh_key

    # Check output file
    check_output_file

    # Generate tfvars file
    generate_tfvars

    # Display summary
    display_summary
}

# Run main function
main "$@"