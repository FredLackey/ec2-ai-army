# Terraform AI Host Army

This Terraform project deploys a configurable number of Ubuntu EC2 instances in AWS, intended for AI-related workloads. The project is organized into separate modules for VPC and instance management.

## State Buckets:
- VPC Module: tfstate-ai-army-vpc
- Instances Module: tfstate-ai-army-instances

## Description

This project provides a complete AWS infrastructure solution for AI workloads:
- **VPC Module**: Creates a dedicated Virtual Private Cloud with public/private subnets, optimized for cost and AI development
- **Instances Module**: Deploys a configurable fleet of Ubuntu EC2 instances within the VPC

The infrastructure is designed to be modular, allowing you to scale your AI compute resources as needed through simple configuration changes.

## Project Structure

- `iac-instances/`: Terraform configuration for EC2 instances
- `iac-vpc/`: Terraform configuration for VPC setup with public/private subnets
- `scripts/`: Helper scripts for AWS operations and configuration generation

## Usage

### Prerequisites

1. AWS CLI installed and configured with your profile
2. Terraform installed
3. Appropriate AWS permissions

### Step 1: Deploy VPC (Optional)

Only run this step if you need to create a new VPC for your AI Army instances.

```bash
cd iac-vpc

# Create state bucket
./scripts/setup-state-bucket.sh <your-profile>

# Generate configuration
../scripts/create-tfvars-vpc.sh -p <your-profile> -r <your-region>

# Deploy
terraform init
terraform apply
```

### Step 2: Discover Your AWS Environment

Run the environment discovery script to identify available VPCs, subnets, and other resources in your AWS region.

```bash
# Discover and document your AWS environment
./scripts/discover-environment.sh -p <your-profile> -r <your-region>
```

This will generate a detailed report showing all VPCs, subnets, security groups, and instances in your region. Use this information to identify the VPC ID and subnet ID you want to use for your instances.

### Step 3: Deploy EC2 Instances

```bash
cd ../iac-instances

# Create state bucket
./scripts/setup-state-bucket.sh <your-profile>

# Generate configuration using VPC and subnet IDs from discovery (example: 3 instances)
# Replace <vpc-id> and <subnet-id> with values from the discovery report
../scripts/create-tfvars-instances.sh -p <your-profile> -r <your-region> \
  -v <vpc-id> -s <subnet-id> -c 3

# Deploy
terraform init
terraform apply

# Get SSH commands
terraform output ssh_connection_commands
```

### Step 4: Access Instances

```bash
# SSH to an instance
ssh -i ./ai-army-shared.pem ubuntu@<instance-ip>

# Or use the connection script
../scripts/connect-to-instance.sh -i 1
```

### Cleanup

```bash
# Destroy instances first
cd iac-instances
terraform destroy

# Then destroy VPC
cd ../iac-vpc
terraform destroy
```

### Finding an Ubuntu AMI (Optional)

By default, the Terraform configuration will automatically select the latest Ubuntu 22.04 LTS AMI for your region, so you don't need to specify an AMI ID manually.

However, if you want to use a specific Ubuntu version or see what AMI options are available, you can use the provided helper script:

```bash
./scripts/find-ubuntu-amis.sh -p <aws-profile> -r <aws-region> -v 22.04 -l
```

This script will show the latest recommended AMI ID, which can then be used with the `-a` option in the `create-tfvars-instances.sh` script if desired.


## Future Work

-   Develop user data scripts using cloud-init to bootstrap the instances with necessary AI tools and libraries.
-   Add options for different instance types and storage configurations.