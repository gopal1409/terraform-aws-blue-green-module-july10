variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name, for example dev, test, or prod."
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "Map of subnet configurations."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "instances" {
  description = "Map of EC2 instance configurations."
  type = map(object({
    subnet_key    = string
    instance_type = string
    instance_name = string
    key_name      = string
  }))
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to access EC2 over SSH. Restrict this in real environments."
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Application port exposed by the EC2 instances and target group."
  type        = number
  default     = 80
}

variable "enable_https" {
  description = "Reserved for future HTTPS listener support."
  type        = bool
  default     = false
}
