#if you do not define the varaible type it will take the same as string
variable "project" {
  
}

variable "environment" {
  
}

variable "vpc_cidr" {
  
}
variable "tags" {
  type = map(string)
}

variable "public_subnets" {
  description = "The name of the public subnet"
  type = map(object({
    az   = string
    cidr = string

  }))
}

variable "private_subnets" {
  description = "The name of the public subnet"
  type = map(object({
    az   = string
    cidr = string

  }))
}
