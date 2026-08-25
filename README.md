# Terraform AWS Blue-Green Module

> **Canva-style workflow: how Terraform calls these GitHub modules and turns them into AWS infrastructure**

```text
┌──────────────────────┐
│  1. Your Terraform   │
│     project          │
│     main.tf          │
└──────────┬───────────┘
           │
           │ source = git::https://github.com/...
           v
┌─────────────────────────────────────────────────────┐
│  2. GitHub Terraform Module Repository              │
│                                                     │
│  modules/networking   ──> VPC + public/private     │
│                            subnets                  │
│                                                     │
│  modules/security     ──> ALB + EC2 security       │
│                            groups                   │
│                                                     │
│  modules/data         ──> Latest Ubuntu AMI         │
│                            from SSM                 │
│                                                     │
│  modules/loadbalancer ──> ALB + Target Group        │
│                            + Listener               │
│                                                     │
│  modules/ec2          ──> Ubuntu EC2 instances     │
│                            registered in TG         │
└──────────────────────────┬──────────────────────────┘
                           │
                           v
                 ┌──────────────────┐
                 │ 3. terraform init│
                 │ Download modules │
                 │ + providers      │
                 └────────┬─────────┘
                          │
                          v
                 ┌──────────────────┐
                 │ 4. terraform     │
                 │    validate      │
                 └────────┬─────────┘
                          │
                          v
                 ┌──────────────────┐
                 │ 5. terraform plan│
                 │ Review changes   │
                 └────────┬─────────┘
                          │
                          v
                 ┌──────────────────┐
                 │ 6. terraform     │
                 │    apply         │
                 └────────┬─────────┘
                          │
                          v
             ┌─────────────────────────────┐
             │           AWS               │
             │                             │
             │ Internet                   │
             │    ↓                        │
             │    ALB                     │
             │    ↓                        │
             │ Target Group               │
             │   ↙       ↘                │
             │ EC2       EC2              │
             │ private   private           │
             │ subnets  subnets            │
             └─────────────┬───────────────┘
                           │
                           v
                 ┌──────────────────┐
                 │ Terraform State  │
                 │ Outputs / Drift  │
                 └──────────────────┘

                 Cleanup when finished
                           │
                           v
                 ┌──────────────────┐
                 │ terraform destroy│
                 └──────────────────┘
```

## 1. What this repository provides

Reusable Terraform modules for deploying an AWS application foundation:

- `networking` — VPC, public subnets, private subnets, Internet Gateway and public routing
- `security` — configurable ALB and web/EC2 security groups
- `data` — current Ubuntu 24.04 LTS AMI lookup through AWS Systems Manager Parameter Store
- `loadbalancer` — Application Load Balancer, target group and HTTP listener
- `ec2` — Ubuntu EC2 instances registered behind the ALB target group

## 2. Repository structure

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

## 3. How to use the modules from Terraform

Create a **new Terraform project**. For example:

```text
my-application/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

Your `main.tf` calls this GitHub repository using Terraform's Git source syntax.

### GitHub source format

```hcl
source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/<module-name>?ref=<tag-or-commit>"
```

The `//terraform-bluegreen-aws/modules/<module-name>` part tells Terraform which subdirectory is the module.

### Recommended versioning

For reusable infrastructure, pin the module to a tag or commit instead of a moving branch:

```hcl
source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/networking?ref=v1.0.0"
```

You can also use a commit SHA:

```hcl
source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/networking?ref=<commit-sha>"
```

## 4. End-to-end Terraform configuration

### Step 1 — Terraform and AWS provider

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

### Step 2 — Root input variables

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
  description = "VPC CIDR block."
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

### Step 3 — Networking module

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

Creates the base network and exposes:

```text
vpc_id
public_subnet_ids
public_subnet_id_list
private_subnet_ids
private_subnet_id_list
```

### Step 4 — Security module

```hcl
module "security" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/security?ref=v1.0.0"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  tags        = var.tags

  web_ingress_rules = [
    {
      description = "HTTP from VPC/ALB"
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

Outputs:

```text
web_sg_id
alb_sg_id
```

> For production, restrict the EC2/web ingress rule to the ALB security group rather than opening the application port to a broad CIDR.

### Step 5 — Ubuntu AMI data module

```hcl
module "data" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/data?ref=v1.0.0"
}
```

Output:

```hcl
module.data.ubuntu_ami_id
```

The module resolves the Ubuntu AMI dynamically through an AWS SSM public parameter instead of hard-coding an AMI ID.

### Step 6 — Load Balancer module

```hcl
module "loadbalancer" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/loadbalancer?ref=v1.0.0"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_id_list
  security_group_ids = [module.security.alb_sg_id]

  target_port = 80
  tags        = var.tags
}
```

Outputs:

```text
alb_id
a lb_arn
alb_dns_name
target_group_id
target_group_arn
listener_arn
```

### Step 7 — EC2 module behind the Load Balancer

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

Outputs:

```text
instance_ids
private_ips
instance_arns
target_group_attachment_ids
```

## 5. Module dependency flow

```text
                   ┌─────────────────┐
                   │  networking     │
                   │  VPC + subnets  │
                   └────────┬────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
              v                           v
     ┌─────────────────┐         ┌─────────────────┐
     │    security     │         │      data       │
     │ ALB SG + Web SG │         │ Ubuntu AMI      │
     └────────┬────────┘         └────────┬────────┘
              │                           │
              v                           v
     ┌─────────────────┐         ┌─────────────────┐
     │  loadbalancer   │         │       ec2       │
     │ ALB + Target TG │────────>│ Ubuntu instances│
     └─────────────────┘         └─────────────────┘
```

## 6. Terraform workflow

Run these commands from your **calling Terraform project**:

```bash
# 1. Verify AWS credentials
aws sts get-caller-identity

# 2. Download providers and GitHub modules
terraform init

# 3. Format the configuration
terraform fmt -recursive

# 4. Validate Terraform configuration
terraform validate

# 5. Preview infrastructure changes
terraform plan

# 6. Create/update AWS infrastructure
terraform apply

# 7. Review outputs
terraform output

# 8. Preview cleanup
terraform plan -destroy

# 9. Remove the lab infrastructure
terraform destroy
```

## 7. Verify the ALB and EC2 targets

Get the ALB DNS name:

```bash
terraform output -raw alb_dns_name
```

Check the target group:

```bash
terraform output -raw target_group_arn
```

Then:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)"
```

Expected state for healthy instances:

```text
healthy
```

## 8. Module inputs

### Networking

| Variable | Type | Purpose |
|---|---|---|
| `project` | `string` | Project name |
| `environment` | `string` | Environment name |
| `vpc_cidr` | `string` | VPC CIDR |
| `public_subnets` | `map(object(...))` | Public subnet definitions |
| `private_subnets` | `map(object(...))` | Private subnet definitions |
| `tags` | `map(string)` | Resource tags |

### Security

| Variable | Type | Purpose |
|---|---|---|
| `project` | `string` | Project name |
| `environment` | `string` | Environment name |
| `vpc_id` | `string` | VPC ID |
| `web_ingress_rules` | `list(object(...))` | EC2/web ingress rules |
| `alb_ingress_rules` | `list(object(...))` | ALB ingress rules |
| `egress_rules` | `list(object(...))` | Egress rules |
| `tags` | `map(string)` | Resource tags |

### Data

| Variable | Type | Default |
|---|---|---|
| `ubuntu_ami_parameter` | `string` | Ubuntu 24.04 amd64 SSM public parameter |

### Load Balancer

| Variable | Type | Default |
|---|---|---:|
| `project` | `string` | required |
| `environment` | `string` | required |
| `vpc_id` | `string` | required |
| `subnet_ids` | `list(string)` | required |
| `security_group_ids` | `list(string)` | required |
| `internal` | `bool` | `false` |
| `idle_timeout` | `number` | `60` |
| `enable_deletion_protection` | `bool` | `false` |
| `target_port` | `number` | `80` |
| `target_protocol` | `string` | `HTTP` |
| `target_type` | `string` | `instance` |
| `health_check_path` | `string` | `/` |
| `health_check_protocol` | `string` | `HTTP` |
| `health_check_matcher` | `string` | `200` |
| `tags` | `map(string)` | `{}` |

### EC2

| Variable | Type | Default |
|---|---|---:|
| `project` | `string` | required |
| `environment` | `string` | required |
| `ami_id` | `string` | required |
| `instance_type` | `string` | `t3.micro` |
| `instance_count` | `number` | `2` |
| `subnet_ids` | `list(string)` | required |
| `security_group_ids` | `list(string)` | required |
| `associate_public_ip_address` | `bool` | `false` |
| `user_data` | `string` | `null` |
| `attach_to_load_balancer` | `bool` | `true` |
| `target_group_arn` | `string` | `null` |
| `target_port` | `number` | `80` |
| `tags` | `map(string)` | `{}` |

## 9. Module outputs

### Networking

```text
vpc_id
public_subnet_ids
public_subnet_id_list
private_subnet_ids
private_subnet_id_list
```

### Security

```text
web_sg_id
alb_sg_id
```

### Data

```text
ubuntu_ami_id
```

### Load Balancer

```text
alb_id
alb_arn
alb_dns_name
target_group_id
target_group_arn
listener_arn
```

### EC2

```text
instance_ids
private_ips
instance_arns
target_group_attachment_ids
```

## 10. Recommended production pattern

```text
Internet
   |
 HTTPS :443
   |
   v
+-----------------------+
| ALB public subnets    |
| ACM certificate       |
| WAF (optional)        |
+-----------+-----------+
            |
            v
+-----------------------+
| Target Group          |
+-----------+-----------+
            |
            v
+-----------------------+
| EC2 private subnets   |
| No public IP          |
| ALB-only ingress      |
+-----------------------+
```

For production, consider Auto Scaling Groups for EC2 capacity, HTTPS/ACM, ALB access logs, WAF where needed, Systems Manager Session Manager instead of public SSH, tightly scoped security-group rules, encrypted remote Terraform state, and pinned module versions.

## 11. Security

Never commit AWS access keys, secret keys, private keys, passwords, or sensitive Terraform state. Prefer the AWS standard credential chain, IAM roles, IAM Identity Center, or OIDC-based short-lived credentials.

## 12. Cleanup

```bash
terraform plan -destroy
terraform destroy
```

The module repository is intended as a reusable learning foundation for AWS Terraform and blue-green deployment patterns.
