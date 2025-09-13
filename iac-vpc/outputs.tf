# VPC Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.ai_dev_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.ai_dev_vpc.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.ai_dev_vpc.arn
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public_subnet.cidr_block
}

output "public_subnet_arn" {
  description = "ARN of the public subnet"
  value       = aws_subnet.public_subnet.arn
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private_subnet.id
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet"
  value       = aws_subnet.private_subnet.cidr_block
}

output "private_subnet_arn" {
  description = "ARN of the private subnet"
  value       = aws_subnet.private_subnet.arn
}

# Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.ai_dev_igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.nat_gateway[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat_gateway_eip[0].public_ip : null
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private_rt.id
}

# Availability Zone
output "availability_zone" {
  description = "Availability zone used for the subnets"
  value       = var.availability_zone
}

# Summary Output for Easy Reference
output "vpc_summary" {
  description = "Summary of VPC configuration for easy reference"
  value = {
    vpc_id              = aws_vpc.ai_dev_vpc.id
    vpc_cidr            = aws_vpc.ai_dev_vpc.cidr_block
    public_subnet_id    = aws_subnet.public_subnet.id
    private_subnet_id   = aws_subnet.private_subnet.id
    availability_zone   = var.availability_zone
    nat_gateway_enabled = var.enable_nat_gateway
  }
}

# Export outputs to JSON file for offline reference
resource "local_file" "outputs_json" {
  filename = "${path.module}/outputs.json"
  content = jsonencode({
    vpc_id                     = aws_vpc.ai_dev_vpc.id
    vpc_cidr                   = aws_vpc.ai_dev_vpc.cidr_block
    vpc_arn                    = aws_vpc.ai_dev_vpc.arn
    public_subnet_id           = aws_subnet.public_subnet.id
    public_subnet_cidr         = aws_subnet.public_subnet.cidr_block
    public_subnet_arn          = aws_subnet.public_subnet.arn
    private_subnet_id          = aws_subnet.private_subnet.id
    private_subnet_cidr        = aws_subnet.private_subnet.cidr_block
    private_subnet_arn         = aws_subnet.private_subnet.arn
    internet_gateway_id        = aws_internet_gateway.ai_dev_igw.id
    nat_gateway_id             = var.enable_nat_gateway ? aws_nat_gateway.nat_gateway[0].id : null
    nat_gateway_public_ip      = var.enable_nat_gateway ? aws_eip.nat_gateway_eip[0].public_ip : null
    public_route_table_id      = aws_route_table.public_rt.id
    private_route_table_id     = aws_route_table.private_rt.id
    availability_zone          = var.availability_zone
    region                     = var.aws_region
    environment                = var.environment
    vpc_name                   = var.vpc_name
    created_at                 = timestamp()
  })
}