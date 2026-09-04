terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Backend belongs to the ROOT CALLER, not the reusable module.
  backend "s3" {
    bucket       = "gopal-terraform-state-2026"
    key          = "dev/gopal-projecty.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "web_alb" {
  source = "./modules/web-alb"

  project_name    = var.project_name
  environment     = var.environment
  vpc_cidr_block  = var.vpc_cidr_block
  subnets         = var.subnets
  instances       = var.instances
  ssh_cidr_blocks = var.ssh_cidr_blocks
  app_port        = var.app_port
}
