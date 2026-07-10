output "web_sg_id" {
  description = "web_security group"
  value = aws_security_group.web_sg
}
output "alb_sg_id" {
  description = "alb security group"
  value = aws_security_group.alb_sg
}