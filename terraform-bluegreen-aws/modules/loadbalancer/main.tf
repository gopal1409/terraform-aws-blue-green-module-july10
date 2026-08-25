resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
  idle_timeout       = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "this" {
  name        = "${var.project}-${var.environment}-tg"
  port        = var.target_port
  protocol    = var.target_protocol
  target_type = var.target_type
  vpc_id      = var.vpc_id

  health_check {
    enabled             = var.health_check_enabled
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = var.health_check_matcher
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
