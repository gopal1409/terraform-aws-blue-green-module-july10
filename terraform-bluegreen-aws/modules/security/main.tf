locals {
  web_ports = [22, 80, 443]
}

resource "aws_security_group" "web_sg" {
  name   = "${var.project}-${var.environment}-web-sg"
  vpc_id = var.vpc_id
  dynamic "ingress" {
    for_each = local.web_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }

  }
  egress {
    
    
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]

      }
      tags = {
    Name = "${var.project}-${var.environment}-web-sg"
   
  }
}
###############################
###alb-security-group
##############################
resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${var.environment}-web-sg"
  description = "allow http traffic to alb"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.project}-${var.environment}-alb-sg"
   
  }
}