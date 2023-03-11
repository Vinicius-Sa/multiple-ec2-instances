locals {
  create = var.create

  is_t_instance_type = replace(var.instance_type, "/^t(2|3|3a){1}\\..*$/", "1") == "1" ? true : false
}

data "aws_ssm_parameter" "this" {
  count = local.create ? 1 : 0

  name = var.ami_ssm_parameter
}


resource "aws_instance" "this" {
  count = local.create ? 1 : 0

  instance_type = var.instance_type
  ami           = try(coalesce(var.ami, data.aws_ssm_parameter.this[0].value), null)

  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64

  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  key_name   = var.key_name
  monitoring = var.monitoring

  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  secondary_private_ips       = var.secondary_private_ips

  ebs_optimized = var.ebs_optimized

  tags = var.tags
}