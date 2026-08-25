# EC2 Module

This module launches EC2 instances and optionally registers them behind an Application Load Balancer target group.

## Architecture

```text
Internet
   |
   v
Application Load Balancer
   |
   v
ALB Target Group
   |
   +---- EC2 instance 1
   |
   +---- EC2 instance 2
```

The module does not create the ALB itself. Pass the target group ARN from the `loadbalancer` module.

## Example

```hcl
module "ec2" {
  source = "./modules/ec2"

  project     = var.project
  environment = var.environment

  # Resolved by the modules/data module.
  ami_id        = module.data.ubuntu_ami_id
  instance_type = "t3.micro"
  instance_count = 2

  subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.security.web_sg_id]

  attach_to_load_balancer = true
  target_group_arn         = module.loadbalancer.target_group_arn
  target_port              = 80

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable --now nginx
    echo "Hello from $(hostname)" > /var/www/html/index.html
  EOF

  tags = {
    Project = var.project
  }
}
```

## Important security design

For an internet-facing ALB, the EC2 instances should normally be in private subnets without public IP addresses. The instance security group should allow application traffic from the ALB security group rather than from `0.0.0.0/0`.

For production workloads, consider an Auto Scaling Group instead of a fixed number of `aws_instance` resources so failed instances can be replaced automatically and capacity can scale with demand.
