# Terraform AI Host Army - VPC Infrastructure

This module creates a simplified VPC infrastructure optimized for AI development workloads with one public and one private subnet in a single availability zone.

## State Configuration

The Terraform state for this module uses the S3 bucket: `tfstate-ai-army-vpc`

## Purpose

This module creates a dedicated Virtual Private Cloud (VPC) specifically designed for AI development workloads. It provides a simplified, cost-effective network infrastructure that can be used with the EC2 instances in `iac-instances/`.

**All network settings are fully configurable** through the `terraform.tfvars` file, which can be automatically generated using the convenience script in the `scripts/` folder.

## Features

### Network Architecture
- **Dedicated VPC** with fully configurable CIDR block (default: 10.100.0.0/16)
- **Single AZ deployment** for simplified setup and cost optimization
- **One public subnet** with configurable CIDR (default: 10.100.1.0/24)
- **One private subnet** with configurable CIDR (default: 10.100.10.0/24)
- **Internet Gateway** for public subnet connectivity
- **Optional NAT Gateway** for private subnet outbound internet access

All network ranges, availability zones, and settings are fully configurable via `terraform.tfvars`

### Network Components
- **Route Tables** for public and private subnets
- **VPC DNS** enabled for hostname resolution

### Cost Optimizations
- **Single NAT Gateway** option (can be disabled to save ~$45/month)
- **Single AZ** to minimize cross-AZ data transfer charges

## Prerequisites

1. **AWS CLI and Profile Configuration**:
   ```bash
   # Verify AWS CLI is installed
   aws --version

   # Check if your profile exists
   aws configure list-profiles | grep <your-profile>

   # If using SSO, login
   aws sso login --profile <your-profile>

   # Verify access
   aws sts get-caller-identity --profile <your-profile>
   ```

2. **Terraform State Bucket**:
   ```bash
   # Create the state bucket using the module-specific script
   ./scripts/setup-state-bucket.sh <your-profile>

   # This will create:
   # - S3 bucket: tfstate-ai-army-vpc
   # - DynamoDB table: tfstate-ai-army-vpc-locks
   ```

## Quick Start

1. **Generate terraform.tfvars using the convenience script**:
   ```bash
   # From the root project directory:
   ./scripts/create-tfvars-vpc.sh -p <your-profile> -r <your-region> [OPTIONS]

   # Or from the iac-vpc directory:
   ../scripts/create-tfvars-vpc.sh -p <your-profile> -r <your-region> [OPTIONS]
   ```

   The script automatically:
   - Detects the first available availability zone in your region
   - Calculates appropriate subnet CIDRs based on your VPC CIDR
   - Sets sensible defaults for all configuration options
   - Allows full customization through command-line options

   Common options:
   ```bash
   -c, --cidr <cidr>     # Custom VPC CIDR (default: 10.100.0.0/16)
   -n, --name <name>     # VPC name (default: ai-dev-vpc)
   -e, --environment     # Environment tag (default: development)
   --enable-nat-gateway  # Enable NAT Gateway (default: disabled to save costs)
   -h, --help           # Show all available options
   ```

   Or manually create the configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review the plan**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. **Save the outputs for use with iac-instances**:
   ```bash
   terraform output -json > vpc-outputs.json
   ```

## Integration with EC2 Instances

After deploying this VPC, use the outputs in your `iac-instances/terraform.tfvars`:

```hcl
# Get values from terraform output
vpc_id    = "vpc-xxxxxxxxx"      # from vpc_id output
subnet_id = "subnet-xxxxxxxxx"   # from public_subnet_id or private_subnet_id
```

Or use Terraform data sources to reference the VPC:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "tfstate-ai-army-vpc"
    key    = "terraform.tfstate"
    region = "<your-region>"
  }
}

# Then reference: data.terraform_remote_state.vpc.outputs.vpc_id
```

## Configuration Options

All settings are configurable through `terraform.tfvars`:

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_name` | Name for the VPC | ai-dev-vpc |
| `vpc_cidr` | CIDR block for the VPC | 10.100.0.0/16 |
| `public_subnet_cidr` | CIDR for public subnet | 10.100.1.0/24 |
| `private_subnet_cidr` | CIDR for private subnet | 10.100.10.0/24 |
| `availability_zone` | AZ for subnets | Auto-detected by script |
| `enable_nat_gateway` | Enable NAT for private subnet | false |
| `environment` | Environment tag | development |
| `aws_profile` | AWS CLI profile to use | (required) |
| `aws_region` | AWS region for deployment | (required) |

The convenience script automatically calculates subnet CIDRs and detects availability zones, but all values can be overridden.

## Outputs

The module provides the following outputs:

- `vpc_id` - VPC identifier
- `vpc_cidr` - VPC CIDR block
- `public_subnet_id` - Public subnet ID for internet-facing resources
- `private_subnet_id` - Private subnet ID for internal resources
- `nat_gateway_id` - NAT Gateway ID (if enabled)
- `vpc_summary` - Complete summary of VPC configuration

## Cost Considerations

| Resource | Approximate Monthly Cost | Notes |
|----------|-------------------------|-------|
| VPC | Free | No charge for VPC itself |
| Internet Gateway | Free | No charge for IGW |
| NAT Gateway | ~$45 | Can be disabled if not needed |
| Data Transfer | Variable | Depends on usage |

To minimize costs:
- Set `enable_nat_gateway = false` if private subnet doesn't need internet
- Keep resources in same AZ to avoid cross-AZ charges

## Cleanup

To destroy the VPC and all resources:

```bash
terraform destroy
```

**WARNING**: This will delete all resources. Ensure no EC2 instances are using this VPC first.

## Troubleshooting

1. **CIDR Conflicts**: If you get CIDR overlap errors, use the script with a different CIDR:
   ```bash
   ../scripts/create-tfvars-vpc.sh -p <profile> -r <region> -c 10.200.0.0/16
   ```
   Or modify `vpc_cidr` in terraform.tfvars
2. **Profile Issues**: Ensure AWS profile is configured and has necessary permissions
3. **State Lock**: If terraform is locked, check DynamoDB table for stuck locks

## Security Notes

- Security groups should be managed in the EC2 instances module
- Consider enabling VPC Flow Logs for production use
- Use Systems Manager Session Manager instead of SSH when possible