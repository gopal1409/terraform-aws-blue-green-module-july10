# Terraform AWS Blue-Green Infrastructure Modules

Reusable Terraform modules for building an AWS application platform with networking, security groups, an Ubuntu AMI data lookup, an Application Load Balancer, and EC2 application instances.

Repository: `gopal1409/terraform-aws-blue-green-module-july10`

## Architecture

```text
                         Internet
                            |
                            v
                +-----------------------+
                | Application Load      |
                | Balancer (ALB)        |
                | Public subnets        |
                +-----------+-----------+
                            |
                      Target Group
                            |
               +------------+------------+
               |                         |
               v                         v
        +-------------+           +-------------+
        | EC2 Ubuntu  |           | EC2 Ubuntu  |
        | Private     |           | Private     |
        | subnet      |           | subnet      |
        +-------------+           +-------------+
                 ^                       ^
                 |                       |
                 +------ Web SG --------+

  data module --> current Ubuntu AMI
  networking   --> VPC + public/private subnets
  security     --> ALB + EC2 security groups
  loadbalancer --> ALB + target group + listener
  ec2          --> EC2 instances + target-group attachments
```

## Modules

| Module | Purpose | Main outputs |
|---|---|---|
| `networking` | Creates VPC and public/private subnets | `vpc_id`, public/private subnet IDs |
| `security` | Creates ALB and EC2/web security groups | `alb_sg_id`, `web_sg_id` |
| `data` | Resolves the current Ubuntu 24.04 AMI through AWS SSM | `ubuntu_ami_id` |
| `loadbalancer` | Creates Application Load Balancer, target group and HTTP listener | `alb_dns_name`, `target_group_arn` |
| `ec2` | Launches Ubuntu EC2 instances and registers them with the target group | `instance_ids`, `private_ips` |

## How to consume the modules from GitHub

The recommended pattern is to call each module separately from a root Terraform project. The module `source` points directly to this repository and uses the subdirectory after `//`.

For reproducible deployments, pin the Git reference to a release tag or commit instead of always using `master`.

Example:

```hcl
module "networking" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/networking?ref=v1.0.0"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}
```

> The exact networking variable names should match the current `modules/networking/variables.tf` in the selected version.

## Complete root-module example

Create a separate directory for the environment that consumes the GitHub modules:

```text
my-application-infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── terraform.tfvars
```

### 1. `versions.tf`

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

### 2. `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region where the infrastructure is deployed."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used for resource naming and tags."
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
  description = "Public subnet CIDRs."
  type        = map(string)
  default = {
    public_a = "10.0.1.0/24"
    public_b = "10.0.2.0/24"
  }
}

variable "private_subnets" {
  description = "Private subnet CIDRs."
  type        = map(string)
  default = {
    private_a = "10.0.11.0/24"
    private_b = "10.0.12.0/24"
  }
}
```

### 3. `main.tf` — networking

```hcl
module "networking" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/networking?ref=v1.0.0"

  project         = var.project
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}
```

### 4. `main.tf` — security groups

```hcl
module "security" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/security?ref=v1.0.0"

  project     = var.project
  environment = var.environment
  vpc_id      = module.networking.vpc_id

  # ALB accepts HTTP/HTTPS from the Internet.
  alb_ingress_rules = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # For production, replace the broad EC2 rules with rules whose source
  # is restricted to the ALB security group.
  web_ingress_rules = [
    {
      description = "HTTP from application clients"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}
```

### 5. `main.tf` — Ubuntu AMI data module

```hcl
module "data" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/data?ref=v1.0.0"
}
```

The data module resolves the current Ubuntu AMI for the AWS region used by the provider. Do not hard-code a region-specific Ubuntu AMI ID in the EC2 module.

### 6. `main.tf` — load balancer

```hcl
module "loadbalancer" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/loadbalancer?ref=v1.0.0"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_id_list
  security_group_ids = [module.security.alb_sg_id]

  internal = false
  target_port = 80

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
```

### 7. `main.tf` — EC2 application instances

```hcl
module "ec2" {
  source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/ec2?ref=v1.0.0"

  project        = var.project
  environment    = var.environment
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

  tags = {
    Project     = var.project
    Environment = var.environment
    Role        = "web"
  }
}
```

## Outputs

Create `outputs.tf` in the consuming root project:

```hcl
output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = module.loadbalancer.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = module.loadbalancer.alb_arn
}

output "target_group_arn" {
  description = "ALB target group ARN."
  value       = module.loadbalancer.target_group_arn
}

output "ubuntu_ami_id" {
  description = "Ubuntu AMI selected by the data module."
  value       = module.data.ubuntu_ami_id
}

output "ec2_instance_ids" {
  description = "EC2 instance IDs registered with the target group."
  value       = module.ec2.instance_ids
}

output "ec2_private_ips" {
  description = "Private IP addresses of the application instances."
  value       = module.ec2.private_ips
}
```

## End-to-end execution

### Step 1 — Authenticate to AWS

Use an AWS profile, IAM Identity Center, environment credentials, an IAM role, or another supported AWS credential-chain mechanism. Do not place access keys in Terraform source.

Verify the identity:

```bash
aws sts get-caller-identity
```

### Step 2 — Initialize the consuming project

```bash
terraform init
```

Terraform downloads each GitHub module referenced by `source`.

### Step 3 — Format and validate

```bash
terraform fmt -recursive
terraform validate
```

### Step 4 — Review the plan

```bash
terraform plan
```

Confirm the planned VPC, subnets, security groups, ALB, target group, listener, EC2 instances, and target-group attachments.

### Step 5 — Deploy

```bash
terraform apply
```

After deployment:

```bash
terraform output alb_dns_name
```

Open the returned ALB DNS name in a browser. Traffic should flow through the ALB target group to the EC2 instances.

### Step 6 — Verify the target group

Use the AWS CLI to inspect target health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(terraform output -raw target_group_arn)"
```

Targets should report `healthy` after the application is running and the health check succeeds.

### Step 7 — Destroy the lab

When finished:

```bash
terraform destroy
```

## Blue-green deployment extension

The current `loadbalancer` module creates one target group. For a complete blue-green deployment, create separate `blue` and `green` target groups and use an ALB listener rule/default action to shift traffic between them.

A typical model is:

```text
                         ALB
                          |
                  Listener :80/:443
                          |
             +------------+------------+
             |                         |
        Blue target group         Green target group
             |                         |
        Blue instances             Green instances
```

Deploy the new application version to the inactive environment, validate its health, then switch the listener to the new target group. Keep the old environment available for rapid rollback until the new version is proven stable.

## Production recommendations

### HTTPS

For production, use an ACM certificate and an HTTPS listener on port 443. Redirect HTTP to HTTPS rather than serving application traffic over plain HTTP.

### Security groups

Use this traffic model:

```text
Internet -> ALB security group : 80/443
ALB SG   -> EC2 security group  : application port
```

Do not expose the EC2 application port directly to the Internet.

### EC2 scaling

The EC2 module is intentionally simple for training. Production workloads should generally use an Auto Scaling Group and launch template so instances can be replaced and scaled automatically.

### Terraform state

Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, or plan files. For shared environments, use a protected remote state backend with encryption, access control, and state locking appropriate to the backend.

### Secrets

Do not put passwords, API keys, private keys, or database credentials into Git, `.tfvars`, or `user_data`. Use AWS Secrets Manager, Systems Manager Parameter Store, or another appropriate secret-management system.

## GitHub module source syntax

The general syntax for a Terraform module stored in a GitHub repository is:

```hcl
module "example" {
  source = "git::https://github.com/OWNER/REPOSITORY.git//PATH/TO/MODULE?ref=TAG_OR_COMMIT"
}
```

For this repository:

```hcl
source = "git::https://github.com/gopal1409/terraform-aws-blue-green-module-july10.git//terraform-bluegreen-aws/modules/ec2?ref=v1.0.0"
```

The `//` separates the repository URL from the module's subdirectory. `ref` selects a Git branch, tag, or commit. **Prefer an immutable release tag or commit SHA for production.**

## Module input reference

### Networking

Typical inputs include:

- `project`
- `environment`
- `vpc_cidr`
- `public_subnets`
- `private_subnets`
- availability-zone/networking options defined by the selected module version

Outputs used by the other modules:

- `vpc_id`
- `public_subnet_id_list`
- `private_subnet_id_list`

### Security

Inputs include:

- `project`
- `environment`
- `vpc_id`
- `web_ingress_rules`
- `alb_ingress_rules`
- `egress_rules`
- `tags`

Outputs:

- `web_sg_id`
- `web_sg_arn`
- `alb_sg_id`
- `alb_sg_arn`

### Data

Input:

- `ubuntu_ami_parameter` — defaults to the Ubuntu 24.04 amd64 SSM public parameter.

Output:

- `ubuntu_ami_id`

### Load balancer

Inputs include:

- `project`
- `environment`
- `vpc_id`
- `subnet_ids`
- `security_group_ids`
- `internal`
- `idle_timeout`
- `enable_deletion_protection`
- `target_port`
- `target_protocol`
- `target_type`
- health-check variables
- `tags`

Outputs:

- `alb_id`
- `alb_arn`
- `alb_dns_name`
- `target_group_id`
- `target_group_arn`
- `listener_arn`

### EC2

Inputs include:

- `project`
- `environment`
- `ami_id`
- `instance_type`
- `instance_count`
- `subnet_ids`
- `security_group_ids`
- `associate_public_ip_address`
- `user_data`
- `attach_to_load_balancer`
- `target_group_arn`
- `target_port`
- `tags`

Outputs:

- `instance_ids`
- `private_ips`
- `instance_arns`
- `target_group_attachment_ids`

## Important note about version tags

The examples above use `ref=v1.0.0` to demonstrate the recommended immutable module-consumption pattern. Create and publish a Git tag such as `v1.0.0` after reviewing and testing the module version you intend to consume. Until such a tag exists, use a specific commit SHA or the required branch during development.

## Recommended validation before publishing a module version

From a test/root configuration that consumes the GitHub modules:

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Run the deployment in a disposable AWS environment before publishing a production module tag.
