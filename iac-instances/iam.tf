# IAM role for EC2 instances
resource "aws_iam_role" "ai_army_instance_role" {
  name = "${var.instance_name_prefix}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.instance_name_prefix}-instance-role"
    Environment = var.environment
  }
}

# IAM policy for S3 access to dotfiles bucket
resource "aws_iam_policy" "dotfiles_s3_access" {
  name        = "${var.instance_name_prefix}-dotfiles-s3-access"
  description = "Policy to allow EC2 instances to access dotfiles S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.dotfiles.arn,
          "${aws_s3_bucket.dotfiles.arn}/*"
        ]
      }
    ]
  })
}

# Attach S3 access policy to the role
resource "aws_iam_role_policy_attachment" "dotfiles_s3_access" {
  role       = aws_iam_role.ai_army_instance_role.name
  policy_arn = aws_iam_policy.dotfiles_s3_access.arn
}

# IAM instance profile for EC2 instances
resource "aws_iam_instance_profile" "ai_army_instance_profile" {
  name = "${var.instance_name_prefix}-instance-profile"
  role = aws_iam_role.ai_army_instance_role.name

  tags = {
    Name        = "${var.instance_name_prefix}-instance-profile"
    Environment = var.environment
  }
}

# Additional policy for CloudWatch logs (optional but recommended)
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.instance_name_prefix}-cloudwatch-logs"
  description = "Policy to allow EC2 instances to write to CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# Attach CloudWatch logs policy to the role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ai_army_instance_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}