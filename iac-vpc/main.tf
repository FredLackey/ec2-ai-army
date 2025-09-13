# AI Dev VPC Configuration
# Creates a simplified VPC with one public and one private subnet in a single AZ

# VPC
resource "aws_vpc" "ai_dev_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.vpc_name
    Environment = var.environment
    Project     = "ai-army"
    ManagedBy   = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ai_dev_igw" {
  vpc_id = aws_vpc.ai_dev_vpc.id

  tags = {
    Name        = "${var.vpc_name}-igw"
    Environment = var.environment
    Project     = "ai-army"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.ai_dev_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.vpc_name}-public-${var.availability_zone}"
    Environment = var.environment
    Project     = "ai-army"
    Type        = "Public"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.ai_dev_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name        = "${var.vpc_name}-private-${var.availability_zone}"
    Environment = var.environment
    Project     = "ai-army"
    Type        = "Private"
  }
}

# Elastic IP for NAT Gateway (if enabled)
resource "aws_eip" "nat_gateway_eip" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.vpc_name}-nat-eip"
    Environment = var.environment
    Project     = "ai-army"
  }

  depends_on = [aws_internet_gateway.ai_dev_igw]
}

# NAT Gateway (if enabled)
resource "aws_nat_gateway" "nat_gateway" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_gateway_eip[0].id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name        = "${var.vpc_name}-nat-gateway"
    Environment = var.environment
    Project     = "ai-army"
  }

  depends_on = [aws_internet_gateway.ai_dev_igw]
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ai_dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ai_dev_igw.id
  }

  tags = {
    Name        = "${var.vpc_name}-public-rt"
    Environment = var.environment
    Project     = "ai-army"
    Type        = "Public"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ai_dev_vpc.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat_gateway[0].id
    }
  }

  tags = {
    Name        = "${var.vpc_name}-private-rt"
    Environment = var.environment
    Project     = "ai-army"
    Type        = "Private"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table Association
resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

