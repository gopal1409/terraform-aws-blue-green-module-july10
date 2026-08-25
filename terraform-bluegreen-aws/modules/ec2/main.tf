resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids     = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.user_data

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-web-${count.index + 1}"
  })
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.attach_to_load_balancer ? var.instance_count : 0

  target_group_arn = var.target_group_arn
  target_id        = aws_instance.this[count.index].id
  port             = var.target_port
}
