output "ubuntu_ami_id" {
  description = "The Ubuntu AMI ID resolved from the AWS Systems Manager public parameter."
  value       = data.aws_ssm_parameter.ubuntu_ami.value
}
