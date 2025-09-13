# Deployment Process

## Prerequisites

1. AWS CLI installed and configured with your profile
2. Terraform installed
3. Appropriate AWS permissions

## Step 1: Deploy VPC

```bash
cd iac-vpc

# Create state bucket
./scripts/setup-state-bucket.sh <your-profile>

# Generate configuration
../scripts/create-tfvars-vpc.sh -p <your-profile> -r <your-region>

# Deploy
terraform init
terraform apply

# Save outputs
terraform output -json > ../vpc-outputs.json
```

## Step 2: Deploy EC2 Instances

```bash
cd ../iac-instances

# Create state bucket
./scripts/setup-state-bucket.sh <your-profile>

# Get VPC and subnet IDs from previous step
VPC_ID=$(jq -r .vpc_id.value ../vpc-outputs.json)
SUBNET_ID=$(jq -r .public_subnet_id.value ../vpc-outputs.json)

# Generate configuration (example: 3 instances)
../scripts/create-tfvars-instances.sh -p <your-profile> -r <your-region> \
  -v $VPC_ID -s $SUBNET_ID -c 3

# Deploy
terraform init
terraform apply

# Get SSH commands
terraform output ssh_connection_commands
```

## Step 3: Access Instances

```bash
# SSH to an instance
ssh -i ./ai-army-shared.pem ubuntu@<instance-ip>
```

## Cleanup

```bash
# Destroy instances first
cd iac-instances
terraform destroy

# Then destroy VPC
cd ../iac-vpc
terraform destroy
```

## Helper Scripts

- `scripts/setup-state-bucket.sh` - Creates S3 bucket for Terraform state
- `scripts/create-tfvars-vpc.sh` - Generates VPC configuration
- `scripts/create-tfvars-instances.sh` - Generates instances configuration
- `scripts/find-ubuntu-amis.sh` - Lists available Ubuntu AMIs for a region
