#!/bin/bash

# Script to validate the dotfiles setup before running terraform

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

print_color "$GREEN" "=== Validating Terraform Dotfiles Setup ==="
echo ""

# Track validation status
VALIDATION_PASSED=true

# Check for dotfiles directory
print_color "$YELLOW" "Checking for dotfiles directory..."
if [ -d "$IAC_DIR/dotfiles" ]; then
    print_color "$GREEN" "✓ Dotfiles directory exists"

    # Count files in dotfiles
    FILE_COUNT=$(find "$IAC_DIR/dotfiles" -type f | wc -l)
    print_color "$GREEN" "  Found $FILE_COUNT files in dotfiles directory"
else
    print_color "$RED" "✗ Dotfiles directory not found at $IAC_DIR/dotfiles"
    print_color "$YELLOW" "  Create the directory or ensure your dotfiles are in place"
    VALIDATION_PASSED=false
fi

# Check for terraform files
print_color "$YELLOW" "Checking for required Terraform files..."

REQUIRED_FILES=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "provider.tf"
    "backend.tf"
    "s3_dotfiles.tf"
    "iam.tf"
    "cloud-init.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$IAC_DIR/$file" ]; then
        print_color "$GREEN" "✓ $file exists"
    else
        print_color "$RED" "✗ $file not found"
        VALIDATION_PASSED=false
    fi
done

# Check for terraform.tfvars
print_color "$YELLOW" "Checking for terraform.tfvars..."
if [ -f "$IAC_DIR/terraform.tfvars" ]; then
    print_color "$GREEN" "✓ terraform.tfvars exists"

    # Check for required variables
    print_color "$YELLOW" "  Checking required variables..."

    if grep -q "vpc_id" "$IAC_DIR/terraform.tfvars"; then
        print_color "$GREEN" "  ✓ vpc_id is set"
    else
        print_color "$RED" "  ✗ vpc_id is not set"
        VALIDATION_PASSED=false
    fi

    if grep -q "subnet_id" "$IAC_DIR/terraform.tfvars"; then
        print_color "$GREEN" "  ✓ subnet_id is set"
    else
        print_color "$RED" "  ✗ subnet_id is not set"
        VALIDATION_PASSED=false
    fi

    if grep -q "ami_id" "$IAC_DIR/terraform.tfvars"; then
        print_color "$GREEN" "  ✓ ami_id is set"
    else
        print_color "$RED" "  ✗ ami_id is not set"
        VALIDATION_PASSED=false
    fi
else
    print_color "$RED" "✗ terraform.tfvars not found"
    print_color "$YELLOW" "  Run ./scripts/create-tfvars-instances.sh to create it"
    VALIDATION_PASSED=false
fi

# Check AWS CLI
print_color "$YELLOW" "Checking AWS CLI..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    print_color "$GREEN" "✓ AWS CLI installed (version $AWS_VERSION)"
else
    print_color "$RED" "✗ AWS CLI not installed"
    print_color "$YELLOW" "  Install AWS CLI to upload dotfiles to S3"
    VALIDATION_PASSED=false
fi

# Check Terraform
print_color "$YELLOW" "Checking Terraform..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    print_color "$GREEN" "✓ Terraform installed (version $TF_VERSION)"
else
    print_color "$RED" "✗ Terraform not installed"
    VALIDATION_PASSED=false
fi

# Check for setup.sh in dotfiles (optional but recommended)
print_color "$YELLOW" "Checking for setup.sh in dotfiles (optional)..."
if [ -f "$IAC_DIR/dotfiles/setup.sh" ]; then
    print_color "$GREEN" "✓ setup.sh found - will run automatically on instances"

    # Check if it's executable
    if [ -x "$IAC_DIR/dotfiles/setup.sh" ]; then
        print_color "$GREEN" "  ✓ setup.sh is executable"
    else
        print_color "$YELLOW" "  ⚠ setup.sh is not executable (will be fixed during sync)"
    fi
else
    print_color "$YELLOW" "⚠ No setup.sh found - dotfiles will be copied but not automatically configured"
fi

echo ""
print_color "$GREEN" "=== Validation Summary ==="

if [ "$VALIDATION_PASSED" = true ]; then
    print_color "$GREEN" "✓ All checks passed! You're ready to run terraform."
    echo ""
    print_color "$YELLOW" "Next steps:"
    print_color "$YELLOW" "1. Run: terraform init"
    print_color "$YELLOW" "2. Run: terraform plan"
    print_color "$YELLOW" "3. Run: terraform apply"
    print_color "$YELLOW" "4. After apply, use ./scripts/manage-dotfiles.sh to manage dotfiles"
    exit 0
else
    print_color "$RED" "✗ Some checks failed. Please fix the issues above before proceeding."
    exit 1
fi