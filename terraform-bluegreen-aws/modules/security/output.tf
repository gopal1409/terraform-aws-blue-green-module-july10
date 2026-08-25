output "web_sg_id" {
  description = "ID of the web/EC2 security group."
  value       = aws_security_group.web_sg.id
}

output "web_sg_arn" {
  description = "ARN of the web/EC2 security group."
  value       = aws_security_group.web_sg.arn
}

output "alb_sg_id" {
  description = "ID of the Application Load Balancer security group."
  value       = aws_security_group.alb_sg.id
}

output "alb_sg_arn" {
  description = "ARN of the Application Load Balancer security group."
  value       = aws_security_group.alb_sg.arn
}
