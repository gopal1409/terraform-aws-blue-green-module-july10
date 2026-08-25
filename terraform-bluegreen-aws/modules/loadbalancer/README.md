# Application Load Balancer Module

This module creates an AWS Application Load Balancer (ALB), an HTTP target group, and an HTTP listener.

## Inputs

Required inputs:

- `project`
- `environment`
- `vpc_id`
- `subnet_ids`
- `security_group_ids`

The target port, target protocol, health check settings, deletion protection, and tags are configurable through variables.

## Example

```hcl
module "loadbalancer" {
  source = "./modules/loadbalancer"

  project          = var.project
  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  subnet_ids       = module.networking.public_subnet_ids
  security_group_ids = [module.security.web_sg_id]

  target_port = 80

  tags = {
    Project = var.project
  }
}
```

## Outputs

- `alb_id`
- `alb_arn`
- `alb_dns_name`
- `target_group_id`
- `target_group_arn`
- `listener_arn`

For production, consider HTTPS with an ACM certificate, appropriate listener rules, deletion protection, access logging, and a target security group that permits application traffic only from the ALB security group.
