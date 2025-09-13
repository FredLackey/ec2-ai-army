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