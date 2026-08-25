# Terraform AWS Blue-Green Module

Reusable Terraform modules for deploying a simple AWS application architecture with networking, security groups, an Ubuntu AMI data source, an Application Load Balancer, and EC2 instances registered behind the load balancer.

## Repository structure

```text
terraform-aws-blue-green-module-july10/
├── README.md
└── terraform-bluegreen-aws/
    ├── modules/
    │   ├── networking/
    │   ├── security/
    │   ├── data/
    │   ├── loadbalancer/
    │   └── ec2/
    └── README.md
```

## Architecture

```text
                         Internet
                            |
                            v
                 +----------------------+
                 | Application Load     |
                 | Balancer             |
                 | Public Subnets       |
                 +----------+-----------+
                            |
                       Target Group
                         /       \
                        /         \
                       v           v
                +-----------+ +-----------+
                | EC2 #1    | | EC2 #2    |
                | Ubuntu    | | Ubuntu    |
                | Private   | | Private   |
                | Subnet    | | Subnet    |
                +-----------+ +-----------+
```

## Use the modules from GitHub

The recommended way to consume a module from this repository is to reference a Git tag rather than the moving `master` branch.

For example:

```hcl
module "networking" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/networking?ref=v1.0.0"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  tags        = var.tags
}
```

The same GitHub source pattern is used for the other modules:

```text
https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/<module-name>?ref=<tag-or-commit>
```

> `//` is important because the Terraform modules are stored below `terraform-bluegreen-aws/modules/` inside the repository.

## End-to-end root configuration

Create a separate Terraform project and add a file such as `main.tf`.

### 1. Terraform and AWS provider

```hcl
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 2. Input variables

```hcl
variable "aws_region" {
  description = "AWS region where the infrastructure is created."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name."
  type        = string
  default     = "bluegreen"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet definitions."
  type = map(object({
    az   = string
    cidr = string
  }))

  default = {
    public_a = {
      az   = "us-east-1a"
      cidr = "10.0.1.0/24"
    }
    public_b = {
      az   = "us-east-1b"
      cidr = "10.0.2.0/24"
    }
  }
}

variable "private_subnets" {
  description = "Private subnet definitions."
  type = map(object({
    az   = string
    cidr = string
  }))

  default = {
    private_a = {
      az   = "us-east-1a"
      cidr = "10.0.11.0/24"
    }
    private_b = {
      az   = "us-east-1b"
      cidr = "10.0.12.0/24"
    }
  }
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
```

### 3. Networking module

```hcl
module "networking" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/networking?ref=v1.0.0"

  project         = var.project
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  tags            = var.tags
}
```

The networking module provides the VPC and subnet outputs used by the other modules. The module exposes both subnet maps and convenient subnet-ID lists.

### 4. Security module

```hcl
module "security" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/security?ref=v1.0.0"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = var.tags

  # Restrict these in a real environment.
  web_ingress_rules = [
    {
      description = "HTTP from ALB"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]

  alb_ingress_rules = [
    {
      description = "HTTP from Internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
```

The security module outputs the web and ALB security-group IDs.

### 5. Ubuntu AMI data module

```hcl
module "data" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/data?ref=v1.0.0"
}
```

The module resolves the current Ubuntu 24.04 LTS AMI through an AWS Systems Manager public parameter instead of hard-coding an AMI ID.

The result is available as:

```hcl
module.data.ubuntu_ami_id
```

### 6. Application Load Balancer module

```hcl
module "loadbalancer" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/loadbalancer?ref=v1.0.0"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_id_list
  security_group_ids = [module.security.alb_sg_id]

  target_port = 80

  tags = var.tags
}
```

The load balancer module creates:

- Application Load Balancer
- Target group
- HTTP listener
- Target health checks

### 7. EC2 module

```hcl
module "ec2" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/ec2?ref=v1.0.0"

  project     = var.project
  environment = var.environment

  ami_id         = module.data.ubuntu_ami_id
  instance_type  = "t3.micro"
  instance_count = 2

  subnet_ids = module.networking.private_subnet_id_list

  security_group_ids = [module.security.web_sg_id]

  associate_public_ip_address = false

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

  tags = var.tags
}
```

The EC2 module creates the instances and registers each instance with the ALB target group using `aws_lb_target_group_attachment`.

## Module inputs

### Networking

| Input | Type | Description |
|---|---|---|
| `project` | `string` | Project name |
| `environment` | `string` | Environment name |
| `vpc_cidr` | `string` | VPC CIDR block |
| `public_subnets` | `map(object({az=string,cidr=string}))` | Public subnet definitions |
| `private_subnets` | `map(object({az=string,cidr=string}))` | Private subnet definitions |
| `tags` | `map(string)` | Common tags |

### Security

| Input | Type | Description |
|---|---|---|
| `project` | `string` | Project name |
| `environment` | `string` | Environment name |
| `vpc_id` | `string` | VPC ID |
| `web_ingress_rules` | `list(object(...))` | Web/EC2 ingress rules |
| `alb_ingress_rules` | `list(object(...))` | ALB ingress rules |
| `egress_rules` | `list(object(...))` | Egress rules |
| `tags` | `map(string)` | Additional tags |

### Data

| Input | Type | Default | Description |
|---|---|---|---|
| `ubuntu_ami_parameter` | `string` | Ubuntu 24.04 amd64 public SSM parameter | Parameter containing the Ubuntu AMI ID |

### Load Balancer

| Input | Type | Default | Description |
|---|---|---:|---|
| `project` | `string` | required | Project name |
| `environment` | `string` | required | Environment name |
| `vpc_id` | `string` | required | Target group VPC |
| `subnet_ids` | `list(string)` | required | ALB subnets |
| `security_group_ids` | `list(string)` | required | ALB security groups |
| `internal` | `bool` | `false` | Create internal ALB |
| `target_port` | `number` | `80` | Backend application port |
| `target_protocol` | `string` | `HTTP` | Backend protocol |
| `target_type` | `string` | `instance` | Target type |
| `health_check_path` | `string` | `/` | Health-check path |
| `enable_deletion_protection` | `bool` | `false` | ALB deletion protection |
| `tags` | `map(string)` | `{}` | Tags |

### EC2

| Input | Type | Default | Description |
|---|---|---:|---|
| `project` | `string` | required | Project name |
| `environment` | `string` | required | Environment name |
| `ami_id` | `string` | required | AMI ID |
| `instance_type` | `string` | `t3.micro` | EC2 instance type |
| `instance_count` | `number` | `2` | Number of instances |
| `subnet_ids` | `list(string)` | required | Instance subnets |
| `security_group_ids` | `list(string)` | required | EC2 security groups |
| `associate_public_ip_address` | `bool` | `false` | Public IP assignment |
| `user_data` | `string` | `null` | Instance initialization script |
| `attach_to_load_balancer` | `bool` | `true` | Register instances in target group |
| `target_group_arn` | `string` | `null` | Target group ARN |
| `target_port` | `number` | `80` | Backend port |
| `tags` | `map(string)` | `{}` | Tags |

## Module outputs

### Networking outputs

```text
vpc_id
public_subnet_ids
public_subnet_id_list
private_subnet_ids
private_subnet_id_list
```

### Security outputs

```text
web_sg_id
alb_sg_id
```

### Data outputs

```text
ubuntu_ami_id
```

### Load Balancer outputs

```text
alb_id
alb_arn
alb_dns_name
target_group_id
target_group_arn
listener_arn
```

### EC2 outputs

```text
instance_ids
private_ips
instance_arns
target_group_attachment_ids
```

## Root outputs

In your calling project, useful outputs can be exposed with:

```hcl
output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = module.loadbalancer.alb_dns_name
}

output "ec2_private_ips" {
  description = "Private IP addresses of the application instances."
  value       = module.ec2.private_ips
}

output "ubuntu_ami_id" {
  description = "AMI selected by the data module."
  value       = module.data.ubuntu_ami_id
}
```

## Initialize and deploy

From the root of your calling Terraform project:

```bash
aws sts get-caller-identity
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

After deployment:

```bash
terraform output alb_dns_name
```

Open the returned ALB DNS name in a browser. The ALB forwards traffic to the registered EC2 instances.

## Verify the target group

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)"
```

Healthy EC2 instances should appear with a `healthy` state.

## Destroy the lab

```bash
terraform plan -destroy
terraform destroy
```

## Blue-green extension

The current modules provide the building blocks for blue-green deployments. A typical next step is to create two target groups and two EC2 fleets:

```text
                    ALB
                     |
              Listener / Rule
                 /       \
                /         \
          Blue TG       Green TG
             |              |
        Blue EC2s      Green EC2s
```

Traffic can then be shifted between blue and green target groups through listener rules or weighted forwarding. Keep the two environments independently deployable so rollback means switching traffic back to the previous target group.

## Production considerations

This repository is designed as a teaching/reusable-module foundation. Before production use, consider:

- HTTPS listener with an ACM certificate
- ALB access logging
- WAF where required
- Auto Scaling Groups instead of fixed EC2 instances
- IAM roles instead of instance credentials embedded in files
- Systems Manager Session Manager instead of public SSH
- Private EC2 subnets with controlled outbound access
- A dedicated security group rule allowing application traffic from the ALB security group
- Encrypted and remote Terraform state with access controls and locking
- Versioned module references using Git tags or commit SHAs
- CI validation with `terraform fmt`, `terraform validate`, and security scanning

## Security

Never commit AWS access keys, secret keys, private keys, or Terraform state containing sensitive information. Use the normal AWS credential chain, IAM roles, IAM Identity Center, or OIDC-based short-lived credentials.

## License / usage

This repository is intended for learning and reusable Terraform module development. Review each AWS resource's cost, availability, security, and regional constraints before applying it to a real account.
