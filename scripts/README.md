# Scripts Directory

This directory contains utility scripts to help deploy and manage the EC2 AI Army infrastructure. Each script is designed to simplify specific operations with sensible defaults and comprehensive error handling.

## State Bucket Management

### `setup-state-bucket.sh`
Creates AWS S3 bucket and DynamoDB table for Terraform remote state backend with proper security configuration.

**Usage:**
```bash
./setup-state-bucket.sh -p corp-dev -r us-east-1 -n tfstate-ai-army-vpc
```

**Features:**
- Creates S3 bucket with versioning and encryption
- Creates DynamoDB table for state locking
- Handles SSO authentication automatically
- Validates bucket naming conventions

### `verify-state-bucket.sh`
Verifies the existence and configuration of Terraform state backend resources.

**Usage:**
```bash
./verify-state-bucket.sh -p corp-dev -r us-east-1 -n tfstate-ai-army-vpc
```

**Features:**
- Checks S3 bucket and DynamoDB table existence
- Validates bucket encryption and versioning
- Displays resource status and configuration
- Shows object counts and billing information

### `delete-state-bucket.sh`
Safely deletes S3 bucket and DynamoDB table used for Terraform state with confirmation prompts.

**Usage:**
```bash
./delete-state-bucket.sh -p corp-dev -r us-east-1 -n tfstate-ai-army-vpc
```

**Features:**
- Requires explicit confirmation ("DELETE")
- Removes all objects and versions
- Deletes bucket and DynamoDB table
- Handles versioned buckets properly

## Configuration Generation

### `create-tfvars-vpc.sh`
Generates terraform.tfvars file for the VPC module with calculated subnet CIDRs and availability zones.

**Usage:**
```bash
./create-tfvars-vpc.sh -p corp-dev -r us-east-1 -n ai-dev-vpc
```

**Features:**
- Auto-calculates subnet CIDRs from VPC CIDR
- Detects availability zones automatically
- Cost-optimized defaults (NAT Gateway disabled)
- Supports custom VPC configurations

### `create-tfvars-instances.sh`
Generates terraform.tfvars file for the EC2 instances module with AMI detection and SSH key management.

**Usage:**
```bash
./create-tfvars-instances.sh -p corp-dev -r us-east-1 -v vpc-12345 -s subnet-67890 -c 3
```

**Features:**
- Auto-detects latest Ubuntu 22.04 AMI
- Creates SSH key pairs automatically
- Detects public IP for SSH access
- Calculates cost estimates
- Validates VPC and subnet resources

## AWS Discovery

### `discover-environment.sh`
Comprehensive AWS environment discovery tool that scans and documents all resources in a region.

**Usage:**
```bash
./discover-environment.sh -p corp-dev -r us-east-1
```

**Features:**
- Discovers VPCs, subnets, security groups
- Maps EC2 instances and their configurations
- Identifies key pairs and Elastic IPs
- Generates detailed JSON and visual reports
- Caches results for performance

### `find-ubuntu-amis.sh`
Searches for available Ubuntu AMIs in a specified AWS region with filtering options.

**Usage:**
```bash
./find-ubuntu-amis.sh -p corp-dev -r us-east-1 -v 22.04 -l
```

**Features:**
- Supports multiple Ubuntu versions (20.04, 22.04, 24.04)
- Filters by architecture (x86_64, arm64)
- Shows latest recommended AMI
- Supports both commercial and GovCloud regions
- Multiple output formats (table, JSON, text)

## Instance Management

### `connect-to-instance.sh`
Connects to deployed EC2 instances via SSH using the generated key pairs.

**Usage:**
```bash
./connect-to-instance.sh -i 1
```

**Features:**
- Reads instance IPs from Terraform outputs
- Uses correct SSH key automatically
- Sets proper key permissions
- Shows available instances if target not found

## Common Features

All scripts include:
- **Comprehensive help** with `-h/--help` flag
- **AWS SSO authentication** handling
- **Color-coded output** for better readability
- **Error handling** with clear messages
- **Input validation** and safety checks
- **Detailed logging** of operations

## Script Dependencies

- **AWS CLI**: All scripts require AWS CLI v2
- **jq**: Required for JSON processing
- **curl**: Used for IP detection in instances script
- **ssh**: Required for instance connections

## Security Notes

- Scripts auto-detect and validate AWS credentials
- SSH keys are created with proper permissions (600)
- Public IP detection ensures secure access configuration
- State buckets are created with encryption enabled
- Confirmation prompts prevent accidental deletions