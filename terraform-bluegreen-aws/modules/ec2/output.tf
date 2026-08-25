output "instance_ids" {
  description = "IDs of the EC2 instances."
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "Private IP addresses of the EC2 instances."
  value       = aws_instance.this[*].private_ip
}

output "instance_arns" {
  description = "ARNs of the EC2 instances."
  value       = aws_instance.this[*].arn
}

output "target_group_attachment_ids" {
  description = "Target group attachment IDs for the EC2 instances."
  value       = aws_lb_target_group_attachment.this[*].id
}
