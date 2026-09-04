resource "aws_instance" "web" {
  for_each = var.instances

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = each.value.instance_type
  subnet_id                   = aws_subnet.this[each.value.subnet_key].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = each.value.key_name
  user_data = templatefile("${path.module}/app.sh", {
    project_name = var.project_name
    environment  = var.environment
  })

  tags = merge(local.common_tags, {
    Name = each.value.instance_name
  })
}

resource "aws_lb_target_group" "this" {
  name        = substr("${local.name_prefix}-tg", 0, 32)
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = local.common_tags
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = aws_instance.web

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value.id
  port             = var.app_port
}

resource "aws_lb" "this" {
  name               = substr("${local.name_prefix}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.this : subnet.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
