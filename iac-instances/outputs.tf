output "instance_ids" {
  description = "IDs of all EC2 instances in the army"
  value       = aws_instance.ai_army[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of all EC2 instances"
  value       = aws_eip.ai_army_eip[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of all EC2 instances"
  value       = aws_instance.ai_army[*].private_ip
}

output "instance_public_dns" {
  description = "Public DNS names of all EC2 instances"
  value       = aws_instance.ai_army[*].public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ai_army_sg.id
}

output "key_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.ai_army_key.key_name
}

output "private_key_file" {
  description = "Path to the private key file"
  value       = local_file.private_key.filename
  sensitive   = true
}

output "ssh_connection_commands" {
  description = "SSH commands to connect to each instance"
  value = [
    for idx, ip in aws_eip.ai_army_eip[*].public_ip :
    "ssh -i ${local_file.private_key.filename} ubuntu@${ip}  # ${var.instance_name_prefix}-${idx + 1}"
  ]
}

output "instance_summary" {
  description = "Summary of all instances with their details"
  value = {
    for idx, instance in aws_instance.ai_army :
    "${var.instance_name_prefix}-${idx + 1}" => {
      id         = instance.id
      public_ip  = aws_eip.ai_army_eip[idx].public_ip
      private_ip = instance.private_ip
      type       = instance.instance_type
      state      = instance.instance_state
    }
  }
}

output "army_size" {
  description = "Total number of instances in the army"
  value       = var.instance_count
}

output "dotfiles_s3_bucket" {
  description = "Name of the S3 bucket containing dotfiles"
  value       = aws_s3_bucket.dotfiles.id
}

output "dotfiles_s3_bucket_arn" {
  description = "ARN of the S3 bucket containing dotfiles"
  value       = aws_s3_bucket.dotfiles.arn
}

output "iam_instance_profile" {
  description = "Name of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ai_army_instance_profile.name
}

output "dotfiles_sync_command" {
  description = "Command to manually sync dotfiles from S3 to an instance"
  value       = "sudo /usr/local/bin/sync-dotfiles.sh"
}

output "dotfiles_upload_command" {
  description = "Command to manually upload local dotfiles to S3"
  value       = "aws s3 sync ./dotfiles/ s3://${aws_s3_bucket.dotfiles.id}/dotfiles/ --delete --profile ${var.aws_profile} --region ${var.aws_region}"
}

# Create a local outputs.json file for use by scripts
resource "local_file" "outputs_json" {
  filename = "${path.module}/outputs.json"
  content = jsonencode({
    instances = {
      for idx, instance in aws_instance.ai_army :
      "${var.instance_name_prefix}-${idx + 1}" => {
        id         = instance.id
        public_ip  = aws_eip.ai_army_eip[idx].public_ip
        private_ip = instance.private_ip
        type       = instance.instance_type
        state      = instance.instance_state
      }
    }
    infrastructure = {
      private_key_file = "ai-army-shared.pem"
      security_group_id = aws_security_group.ai_army_sg.id
      key_name = aws_key_pair.ai_army_key.key_name
    }
    army_size = var.instance_count
    dotfiles = {
      s3_bucket = aws_s3_bucket.dotfiles.id
      s3_bucket_arn = aws_s3_bucket.dotfiles.arn
      sync_command = "sudo /usr/local/bin/sync-dotfiles.sh"
      upload_command = "aws s3 sync ./dotfiles/ s3://${aws_s3_bucket.dotfiles.id}/dotfiles/ --delete --profile ${var.aws_profile} --region ${var.aws_region}"
    }
  })
}