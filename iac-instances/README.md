# Terraform AI Host Army - EC2 Instances

This Terraform module deploys a configurable number of Ubuntu EC2 instances in AWS, intended for AI-related workloads.

## State Configuration

The Terraform state for this module uses the S3 bucket: `tfstate-ai-army-instances`

## Description

The goal of this project is to dynamically create a fleet of EC2 instances running Ubuntu. The number of instances can be easily configured through a Terraform variable, allowing you to scale your AI compute resources as needed.

This module provisions EC2 instances with:
- Automatic SSH key generation and management
- S3-based dotfiles synchronization for consistent development environments
- Cloud-init bootstrapping with Docker, Python, and development tools
- IAM roles for secure S3 access
- Automatic dotfiles sync on boot and hourly updates

## Prerequisites

1. **AWS CLI and Profile Configuration**:
   ```bash
   # Verify AWS CLI is installed
   aws --version

   # Configure your AWS profile
   aws configure --profile <your-profile>

   # Or if using SSO
   aws sso login --profile <your-profile>
   ```

2. **VPC Infrastructure**:
   - Deploy the VPC module first (see `../iac-vpc/README.md`)
   - Note the VPC ID and Subnet ID from the outputs

3. **Terraform State Bucket**:
   ```bash
   # Create the state bucket
   ./scripts/setup-state-bucket.sh <your-profile>
   ```

## Quick Start

1. **Generate terraform.tfvars using the convenience script**:
   ```bash
   ./scripts/create-tfvars-instances.sh -p <profile> -r <region> -v <vpc-id> -s <subnet-id> -c <count>
   ```

   Example:
   ```bash
   ./scripts/create-tfvars-instances.sh -p my-profile -r us-east-1 \
     -v vpc-12345 -s subnet-67890 -c 3
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Deploy the instances**:
   ```bash
   terraform apply
   ```

## Configuration

The `terraform.tfvars` file controls all instance settings. The convenience script sets sensible defaults:

| Variable | Description | Default |
|----------|-------------|---------|
| `instance_count` | Number of instances to create | Required |
| `instance_type` | EC2 instance type | t3.micro |
| `instance_name_prefix` | Prefix for instance names | ai-army |
| `ami_id` | Ubuntu AMI ID | Latest Ubuntu 22.04 |
| `root_volume_size` | Root volume size in GB | 10 |
| `root_volume_type` | EBS volume type | gp3 |
| `key_name_prefix` | SSH key pair name prefix | ai-army |
| `enable_monitoring` | Enable detailed CloudWatch monitoring | false |

### Finding an Ubuntu AMI

The base AMI for the EC2 instances can be updated as needed. To find the latest official Ubuntu AMIs for a specific region, you can use the provided helper script:

```bash
../scripts/find-ubuntu-amis.sh -p <aws-profile> -r <aws-region> -v 22.04 -l
```

This script will show the latest recommended AMI ID, which can then be used in your `terraform.tfvars` file.

## Outputs

The module provides the following outputs:

- `instance_ids` - List of EC2 instance IDs
- `instance_public_ips` - List of public IP addresses (Elastic IPs)
- `instance_private_ips` - List of private IP addresses
- `instance_public_dns` - List of public DNS names
- `security_group_id` - Security group ID for the instances
- `key_name` - Name of the SSH key pair
- `ssh_connection_commands` - Ready-to-use SSH commands for each instance
- `dotfiles_s3_bucket` - Name of the S3 bucket containing dotfiles
- `dotfiles_sync_command` - Command to manually sync dotfiles on instances
- `dotfiles_upload_command` - Command to upload local dotfiles to S3

## Dotfiles Management

The module automatically provisions a dotfiles management system:

### Automatic Synchronization
- Dotfiles are stored in an S3 bucket created during deployment
- Each instance syncs dotfiles on boot and every hour via systemd timer
- The `dotfiles/` directory is automatically uploaded to S3 during `terraform apply`

### Manual Management
Use the provided script to manage dotfiles:

```bash
# Upload local dotfiles to S3
./scripts/manage-dotfiles.sh upload

# Sync dotfiles to all instances
./scripts/manage-dotfiles.sh sync

# Sync to a specific instance
./scripts/manage-dotfiles.sh sync -i i-1234567890

# Check sync status
./scripts/manage-dotfiles.sh status
```

### Dotfiles Location on Instances
- Dotfiles are synced to `/home/ubuntu/dotfiles/`
- If a `setup.sh` script exists in the dotfiles directory, it runs automatically
- Sync logs are available at `/var/log/dotfiles-sync.log`

## SSH Access

After deployment, you can access your instances using:

```bash
# The SSH key is saved locally
ssh -i ./ai-army-shared.pem ubuntu@<instance-public-ip>

# Or use the output commands
terraform output ssh_connection_commands
```

## Security

- A new security group is created for each deployment
- SSH access is restricted to the IP address specified during setup
- All root volumes are encrypted by default
- Instance metadata service can be configured for IMDSv2

## Cost Estimates

| Instance Type | vCPUs | RAM | Monthly Cost* |
|--------------|-------|-----|---------------|
| t3.micro | 1 | 1 GB | ~$7.50 |
| t3.small | 2 | 2 GB | ~$15 |
| t3.medium | 2 | 4 GB | ~$30 |
| t3.large | 2 | 8 GB | ~$60 |

*Costs are approximate and vary by region. Add ~$0.80/GB/month for storage.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**WARNING**: This will permanently delete all instances and associated resources.

## Troubleshooting

1. **State Lock Issues**: If terraform is locked, you can force unlock:
   ```bash
   terraform force-unlock <lock-id>
   ```

2. **SSH Connection Issues**:
   - Verify your IP is in the security group
   - Check the instance is in a public subnet
   - Ensure the SSH key has correct permissions (chmod 600)

3. **AMI Not Found**: Use the find-ubuntu-amis.sh script to get valid AMI IDs for your region

## Reference Architecture

This module creates:
- EC2 instances with Elastic IPs
- Security group with customizable ingress rules
- SSH key pair (generated automatically)
- Encrypted EBS root volumes
- Optional CloudWatch detailed monitoring
- S3 bucket for dotfiles storage with versioning and encryption
- IAM role and instance profile for S3 access
- Cloud-init configuration for automated instance setup
- Systemd services for automated dotfiles synchronization