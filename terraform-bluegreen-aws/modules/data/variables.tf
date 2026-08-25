variable "ubuntu_ami_parameter" {
  description = "AWS Systems Manager public parameter containing the Ubuntu AMI ID to use."
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}
