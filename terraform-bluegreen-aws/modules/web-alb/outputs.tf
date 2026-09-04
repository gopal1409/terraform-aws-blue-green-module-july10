output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids" {
  description = "Subnet IDs by subnet key"
  value       = { for key, subnet in aws_subnet.this : key => subnet.id }
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "ubuntu_ami_id" {
  description = "Selected Ubuntu 24.04 AMI ID"
  value       = data.aws_ami.ubuntu.id
}

output "web_instance_details" {
  description = "EC2 instance details"
  value = {
    for key, instance in aws_instance.web : key => {
      id            = instance.id
      public_ip     = instance.public_ip
      private_ip    = instance.private_ip
      instance_type = instance.instance_type
      subnet_id     = instance.subnet_id
    }
  }
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.this.arn
}
