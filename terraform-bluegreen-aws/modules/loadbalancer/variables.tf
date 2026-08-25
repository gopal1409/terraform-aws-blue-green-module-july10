variable "project" {
  description = "Project name used in ALB and target group names."
  type        = string
}

variable "environment" {
  description = "Environment name used in ALB and target group names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the target group is created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where the Application Load Balancer is deployed. Use subnets in at least two Availability Zones for production."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs attached to the Application Load Balancer."
  type        = list(string)
}

variable "internal" {
  description = "Whether the Application Load Balancer is internal."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "ALB idle timeout in seconds."
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection."
  type        = bool
  default     = false
}

variable "target_port" {
  description = "Port on which targets receive traffic."
  type        = number
  default     = 80
}

variable "target_protocol" {
  description = "Protocol used between the ALB and targets."
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Target type for the target group, such as instance, ip, or lambda."
  type        = string
  default     = "instance"
}

variable "health_check_enabled" {
  description = "Enable target health checks."
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "HTTP path used by the target health check."
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocol used by the target health check."
  type        = string
  default     = "HTTP"
}

variable "health_check_port" {
  description = "Reserved for future configurable health-check port support."
  type        = string
  default     = "traffic-port"
}

variable "health_check_matcher" {
  description = "HTTP response codes considered healthy."
  type        = string
  default     = "200"
}

variable "healthy_threshold" {
  description = "Number of consecutive successful health checks required."
  type        = number
  default     = 3
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks required."
  type        = number
  default     = 3
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds."
  type        = number
  default     = 5
}

variable "health_check_interval" {
  description = "Health check interval in seconds."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags applied to the ALB and target group."
  type        = map(string)
  default     = {}
}
