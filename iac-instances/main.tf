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

  # User data script for initial setup
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Set hostname
    hostnamectl set-hostname ${var.instance_name_prefix}-${count.index + 1}

    # Update and upgrade
    apt-get update
    apt-get upgrade -y

    # Install basic packages
    apt-get install -y curl wget git htop tree unzip vim net-tools

    # Install Docker for AI workloads
    apt-get install -y apt-transport-https ca-certificates gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # Install Python3 and pip for AI tools
    apt-get install -y python3 python3-pip python3-venv

    # Configure automatic security updates
    apt-get install -y unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades

    # Create a welcome message
    echo "======================================" > /etc/motd
    echo "Welcome to AI Host Army - Node ${count.index + 1}" >> /etc/motd
    echo "Instance: ${var.instance_name_prefix}-${count.index + 1}" >> /etc/motd
    echo "SSH key: ${var.key_name_prefix}-shared" >> /etc/motd
    echo "======================================" >> /etc/motd

    # Create workspace directory
    mkdir -p /opt/ai-workspace
    chown ubuntu:ubuntu /opt/ai-workspace

    # Log completion
    echo "$(date): User data script completed for ${var.instance_name_prefix}-${count.index + 1}" >> /var/log/user-data.log
  EOF
  )

  tags = {
    Name     = "${var.instance_name_prefix}-${count.index + 1}"
    NodeID   = count.index + 1
    ArmyRole = "worker"
  }
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