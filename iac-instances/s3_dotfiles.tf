# S3 bucket for storing dotfiles
resource "aws_s3_bucket" "dotfiles" {
  bucket        = "${var.aws_profile}-ai-army-dotfiles-${random_string.bucket_suffix.result}"
  force_destroy = true # Allow bucket to be destroyed even if it contains objects

  tags = {
    Name        = "${var.instance_name_prefix}-dotfiles"
    Environment = var.environment
  }
}

# Random string for bucket naming uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning - Disabled to allow easier cleanup
resource "aws_s3_bucket_versioning" "dotfiles" {
  bucket = aws_s3_bucket.dotfiles.id

  versioning_configuration {
    status = "Disabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dotfiles" {
  bucket = aws_s3_bucket.dotfiles.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "dotfiles" {
  bucket = aws_s3_bucket.dotfiles.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload dotfiles directory to S3
resource "null_resource" "upload_dotfiles" {
  # Trigger upload whenever the dotfiles content changes
  triggers = {
    dotfiles_hash = sha256(join("", [for f in fileset("${path.module}/dotfiles", "**/*") : filesha256("${path.module}/dotfiles/${f}")]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Uploading dotfiles to S3 bucket: ${aws_s3_bucket.dotfiles.id}"
      aws s3 sync ${path.module}/dotfiles/ s3://${aws_s3_bucket.dotfiles.id}/dotfiles/ \
        --delete \
        --profile ${var.aws_profile} \
        --region ${var.aws_region}
    EOT
  }

  depends_on = [
    aws_s3_bucket.dotfiles,
    aws_s3_bucket_versioning.dotfiles,
    aws_s3_bucket_server_side_encryption_configuration.dotfiles,
    aws_s3_bucket_public_access_block.dotfiles
  ]
}