#!/bin/bash

# Setup script for S3 state bucket and DynamoDB table for VPC module
# This script creates the AWS resources needed for Terraform remote state

set -e

# Initialize variables
PROFILE=""
REGION=""
BUCKET_NAME="tfstate-ai-army-vpc"
DYNAMODB_TABLE="tfstate-ai-army-vpc-locks"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 -p|--profile <profile> -r|--region <region>

Creates AWS resources for Terraform remote state backend for the VPC module.

Required arguments:
  -p, --profile <profile>    AWS profile to use
  -r, --region <region>      AWS region for resources

Example:
  $0 --profile corp-dev --region us-east-1
  $0 -p corp-prod -r us-west-2

This will create:
  - S3 bucket: tfstate-ai-army-vpc
  - DynamoDB table: tfstate-ai-army-vpc-locks

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PROFILE" ]]; then
    echo "Error: AWS profile is required. Use -p|--profile <profile-name>"
    echo ""
    usage
    exit 1
fi

if [[ -z "$REGION" ]]; then
    echo "Error: AWS region is required. Use -r|--region <region-name>"
    echo ""
    usage
    exit 1
fi

echo "Using AWS profile: $PROFILE"
echo "Using region: $REGION"
echo "Bucket name: $BUCKET_NAME"
echo "DynamoDB table name: $DYNAMODB_TABLE"

# Set AWS profile for all AWS CLI commands
export AWS_PROFILE="$PROFILE"

# Function to check if SSO session is valid
check_sso_session() {
    echo "Checking AWS SSO session..."

    # Try to get caller identity to test if credentials are valid
    if aws sts get-caller-identity --output text --query 'Account' --no-cli-pager >/dev/null 2>&1; then
        echo "✅ AWS credentials are valid"
        return 0
    else
        echo "❌ AWS credentials are not valid or expired"
        return 1
    fi
}

# Function to initiate SSO login
sso_login() {
    echo "Initiating AWS SSO login for profile: $PROFILE"
    aws sso login --profile "$PROFILE" --no-cli-pager

    # Verify login was successful
    if check_sso_session; then
        echo "✅ SSO login successful"
    else
        echo "❌ SSO login failed or credentials still invalid"
        exit 1
    fi
}

# Check SSO session and login if needed
if ! check_sso_session; then
    echo "SSO session is not active or expired. Initiating login..."
    sso_login
fi

echo "Setting up AWS resources for Terraform state backend..."

# Check if bucket exists
if aws s3 ls "s3://$BUCKET_NAME" --no-cli-pager 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket: $BUCKET_NAME"

    # Create bucket
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" --no-cli-pager

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled \
        --no-cli-pager

    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }' \
        --no-cli-pager

    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
        --no-cli-pager

    echo "✅ S3 bucket created and configured: $BUCKET_NAME"
else
    echo "✅ S3 bucket already exists: $BUCKET_NAME"
fi

# Setup DynamoDB table for state locking
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" --no-cli-pager >/dev/null 2>&1; then
    echo "Creating DynamoDB table for state locking: $DYNAMODB_TABLE"

    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --no-cli-pager

    echo "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$REGION" --no-cli-pager

    echo "✅ DynamoDB table created: $DYNAMODB_TABLE"
else
    echo "✅ DynamoDB table already exists: $DYNAMODB_TABLE"
fi

echo "✅ AWS backend resources created successfully!"
echo "✅ State locking enabled with DynamoDB"
echo "💰 DynamoDB cost: ~\$0.01/month for typical usage"
echo ""
echo "Configuration summary:"
echo "  AWS Profile: $PROFILE"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  Region: $REGION"
echo ""
echo "Next steps:"
echo "  export AWS_PROFILE=$PROFILE"
echo "  cd .. && terraform init"
echo "  terraform plan    # Review changes"
echo "  terraform apply   # Deploy infrastructure"