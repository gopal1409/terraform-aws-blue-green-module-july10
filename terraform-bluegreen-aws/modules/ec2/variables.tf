variable "project" {
  description = "Project name used in EC2 instance names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name used in EC2 instance names and tags."
  type        = string
}

variable "ami_id" {
  description = "AMI ID used to launch the EC2 instances. This can be supplied by the data module output."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances to launch."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count > 0
    error_message = "instance_count must be greater than zero."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs used by the EC2 instances. Instances are distributed across the supplied subnets."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be supplied."
  }
}

variable "security_group_ids" {
  description = "Security groups attached to the EC2 instances."
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "Whether to associate public IP addresses with the instances."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Optional user-data script used to configure the EC2 instances."
  type        = string
  default     = null
}

variable "attach_to_load_balancer" {
  description = "Whether to register the EC2 instances with the supplied ALB target group."
  type        = bool
  default     = true
}

variable "target_group_arn" {
  description = "ARN of the Application Load Balancer target group. Required when attach_to_load_balancer is true."
  type        = string
  default     = null
}

variable "target_port" {
  description = "Port on which the EC2 application receives traffic from the load balancer."
  type        = number
  default     = 80
}

variable "tags" {
  description = "Additional tags applied to the EC2 instances."
  type        = map(string)
  default     = {}
}
