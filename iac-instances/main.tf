# Generate a single SSH key pair for all instances
resource "aws_key_pair" "ai_army_key" {
  key_name   = "${var.key_name_prefix}-shared"
  public_key = tls_private_key.ai_army_key.public_key_openssh

  tags = {
    Name = "${var.key_name_prefix}-shared"
  }
}

# Generate private key for SSH access
resource "tls_private_key" "ai_army_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.ai_army_key.private_key_pem
  filename        = "${path.module}/${var.key_name_prefix}-shared.pem"
  file_permission = "0600"
}

# Security group for the EC2 instances
resource "aws_security_group" "ai_army_sg" {
  name        = var.security_group_name
  description = "Security group for AI Army EC2 instances"
  vpc_id      = var.vpc_id

  # SSH access from allowed CIDR blocks
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP access from allowed CIDR blocks
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS access from allowed CIDR blocks
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow communication between instances in the army
  ingress {
    description = "Internal communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.security_group_name
  }
}

# EC2 instances (the army)
resource "aws_instance" "ai_army" {
  count = var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.ai_army_key.key_name
  vpc_security_group_ids = [aws_security_group.ai_army_sg.id]
  subnet_id             = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ai_army_instance_profile.name

  # Enable detailed monitoring
  monitoring = var.enable_monitoring

  # Root block device
  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
    encrypted   = true

    tags = {
      Name = "${var.instance_name_prefix}-${count.index + 1}-root"
    }
  }

  # User data using cloud-init configuration
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    hostname         = "${var.instance_name_prefix}-${count.index + 1}"
    node_name        = "Node ${count.index + 1}"
    key_name         = "${var.key_name_prefix}-shared"
    s3_bucket_name   = aws_s3_bucket.dotfiles.id
    aws_region       = var.aws_region
  })

  tags = {
    Name     = "${var.instance_name_prefix}-${count.index + 1}"
    NodeID   = count.index + 1
    ArmyRole = "worker"
  }

  depends_on = [
    aws_iam_instance_profile.ai_army_instance_profile,
    aws_s3_bucket.dotfiles,
    null_resource.upload_dotfiles
  ]
}

# Elastic IPs for the instances
resource "aws_eip" "ai_army_eip" {
  count = var.instance_count

  instance = aws_instance.ai_army[count.index].id
  domain   = "vpc"

  tags = {
    Name   = "${var.instance_name_prefix}-${count.index + 1}-eip"
    NodeID = count.index + 1
  }

  depends_on = [aws_instance.ai_army]
}