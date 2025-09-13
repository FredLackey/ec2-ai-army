#!/bin/bash

# Script to manage dotfiles for AI Army EC2 instances
# This script helps upload dotfiles to S3 and trigger sync on instances

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IAC_DIR="$(dirname "$SCRIPT_DIR")"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    upload      Upload local dotfiles to S3 bucket
    sync        Sync dotfiles from S3 to all EC2 instances
    status      Check dotfiles sync status on instances
    help        Show this help message

Options:
    -p, --profile   AWS profile to use (default: from terraform.tfvars)
    -r, --region    AWS region (default: from terraform.tfvars)
    -i, --instance  Specific instance ID (for sync command)
    -h, --help      Show this help message

Examples:
    $0 upload                    # Upload dotfiles to S3
    $0 sync                      # Sync to all instances
    $0 sync -i i-1234567890     # Sync to specific instance
    $0 status                    # Check sync status

EOF
}

# Function to get terraform output
get_terraform_output() {
    local output_name=$1
    cd "$IAC_DIR"
    terraform output -raw "$output_name" 2>/dev/null || echo ""
}

# Function to upload dotfiles to S3
upload_dotfiles() {
    print_color "$GREEN" "=== Uploading Dotfiles to S3 ==="

    # Get S3 bucket name from terraform
    local s3_bucket=$(get_terraform_output "dotfiles_s3_bucket")

    if [ -z "$s3_bucket" ]; then
        print_color "$RED" "Error: Could not get S3 bucket name. Have you run 'terraform apply'?"
        exit 1
    fi

    # Check if dotfiles directory exists
    if [ ! -d "$IAC_DIR/dotfiles" ]; then
        print_color "$RED" "Error: Dotfiles directory not found at $IAC_DIR/dotfiles"
        exit 1
    fi

    print_color "$YELLOW" "Uploading from: $IAC_DIR/dotfiles"
    print_color "$YELLOW" "Uploading to: s3://$s3_bucket/dotfiles/"

    # Upload to S3
    aws s3 sync "$IAC_DIR/dotfiles/" "s3://$s3_bucket/dotfiles/" \
        --delete \
        --profile "$AWS_PROFILE" \
        --region "$AWS_REGION"

    print_color "$GREEN" "✓ Dotfiles uploaded successfully!"
}

# Function to sync dotfiles on instances
sync_dotfiles() {
    local instance_id=$1

    print_color "$GREEN" "=== Syncing Dotfiles on EC2 Instances ==="

    if [ -n "$instance_id" ]; then
        # Sync specific instance
        print_color "$YELLOW" "Syncing dotfiles on instance: $instance_id"

        aws ssm send-command \
            --instance-ids "$instance_id" \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=["/usr/local/bin/sync-dotfiles.sh"]' \
            --profile "$AWS_PROFILE" \
            --region "$AWS_REGION" \
            --output json
    else
        # Get all instance IDs
        local instance_ids=$(get_terraform_output "instance_ids" | tr -d '[]"' | tr ',' ' ')

        if [ -z "$instance_ids" ]; then
            print_color "$RED" "Error: No instances found. Have you run 'terraform apply'?"
            exit 1
        fi

        print_color "$YELLOW" "Syncing dotfiles on all instances..."

        for id in $instance_ids; do
            print_color "$YELLOW" "  - Syncing $id"
            aws ssm send-command \
                --instance-ids "$id" \
                --document-name "AWS-RunShellScript" \
                --parameters 'commands=["/usr/local/bin/sync-dotfiles.sh"]' \
                --profile "$AWS_PROFILE" \
                --region "$AWS_REGION" \
                --output json > /dev/null
        done
    fi

    print_color "$GREEN" "✓ Sync commands sent successfully!"
    print_color "$YELLOW" "Note: Check status with '$0 status' in a few moments"
}

# Function to check sync status
check_status() {
    print_color "$GREEN" "=== Checking Dotfiles Sync Status ==="

    # Get instance IPs for SSH commands
    local ssh_commands=$(get_terraform_output "ssh_connection_commands")

    if [ -z "$ssh_commands" ]; then
        print_color "$RED" "Error: No instances found. Have you run 'terraform apply'?"
        exit 1
    fi

    print_color "$YELLOW" "To check the sync status on each instance, SSH in and run:"
    print_color "$YELLOW" "  tail -f /var/log/dotfiles-sync.log"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "Or check systemd service status:"
    print_color "$YELLOW" "  systemctl status dotfiles-sync.service"
    print_color "$YELLOW" "  systemctl status dotfiles-sync.timer"
    print_color "$YELLOW" ""
    print_color "$YELLOW" "SSH commands for your instances:"
    echo "$ssh_commands" | while IFS= read -r cmd; do
        print_color "$YELLOW" "  $cmd"
    done
}

# Parse terraform.tfvars for defaults
if [ -f "$IAC_DIR/terraform.tfvars" ]; then
    AWS_PROFILE=$(grep -E '^aws_profile' "$IAC_DIR/terraform.tfvars" | cut -d'"' -f2 || echo "default")
    AWS_REGION=$(grep -E '^aws_region' "$IAC_DIR/terraform.tfvars" | cut -d'"' -f2 || echo "us-east-1")
else
    AWS_PROFILE="default"
    AWS_REGION="us-east-1"
fi

# Parse command
COMMAND=$1
shift

# Parse options
INSTANCE_ID=""
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
        -i|--instance)
            INSTANCE_ID="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_color "$RED" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Execute command
case $COMMAND in
    upload)
        upload_dotfiles
        ;;
    sync)
        sync_dotfiles "$INSTANCE_ID"
        ;;
    status)
        check_status
        ;;
    help|"")
        usage
        ;;
    *)
        print_color "$RED" "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac