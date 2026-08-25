output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Map of public subnet names to subnet IDs."
  value = {
    for k, v in aws_subnet.public : k => v.id
  }
}

output "public_subnet_id_list" {
  description = "List of public subnet IDs, suitable for passing to load balancer modules."
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "Map of private subnet names to subnet IDs."
  value = {
    for k, v in aws_subnet.private : k => v.id
  }
}

output "private_subnet_id_list" {
  description = "List of private subnet IDs, suitable for passing to EC2 modules."
  value       = values(aws_subnet.private)[*].id
}
