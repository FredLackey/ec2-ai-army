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
- `assets/`: Reference implementations and examples

## Quick Start

For a complete step-by-step deployment guide with commands, see **[PROCESS.md](./PROCESS.md)**.

### Overview

1. **Deploy VPC** - Create the network infrastructure (`iac-vpc/`)
2. **Deploy Instances** - Create EC2 instances in the VPC (`iac-instances/`)
3. **Access** - SSH into your instances using generated keys

The convenience scripts handle configuration generation and AWS setup automatically.

### Finding an Ubuntu AMI

The base AMI for the EC2 instances can be updated as needed. To find the latest official Ubuntu AMIs for a specific region, you can use the provided helper script:

```bash
./scripts/find-ubuntu-amis.sh -p <aws-profile> -r <aws-region> -v 22.04 -l
```

This script will show the latest recommended AMI ID, which can then be used in your `terraform.tfvars` file.

## Architectural Patterns

This package follows the patterns and best practices established in two other successful IaC projects:

-   `assets/ubuntu-only`: A simple, single Ubuntu EC2 instance deployment.
-   `assets/ubuntu-apache`: A more complex deployment of an Ubuntu instance with Apache and S3 integration.

Reviewing these packages can provide insight into the structure and approach used here.

## Future Work

-   Develop user data scripts using cloud-init to bootstrap the instances with necessary AI tools and libraries.
-   Add options for different instance types and storage configurations.