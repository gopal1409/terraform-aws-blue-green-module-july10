# Reads the latest Ubuntu 24.04 LTS AMI published by Canonical for the selected architecture.
# AWS Systems Manager public parameters are region-aware, so the same module works across AWS regions.
data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ami_parameter
}
