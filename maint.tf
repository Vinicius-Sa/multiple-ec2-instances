provider "aws" {
  region = "us-east-1"
}

terraform {

  required_version = "~> 1.2.6"

  required_providers {
    aws  = "~> 3.74.3"
  }

  backend "s3" {
    bucket = "../.."
    key    = "../.."
    region = "us-east-1"
  }
}

################################################################################
# LOCALS. METADA MySql | Web-server  SCRIPT 
################################################################################

locals {
  resource  = "${var.project}-${var.service_name}-${var.environment}"
  log_prefix  = "logs/${var.environment}"
  environment = var.environment
  user_data = <<-EOT
  #!/bin/bash
  echo "Hello Terraform!"
  touch /test
  EOT
  multiple_instances = {
    web = {
      instance_type     = var.instance_type
      availability_zone = element(module.network.aws_all_subnets_az, 0)
      subnet_id         = element(module.network.aws_all_subnets_id_private, 0)
      root_block_device = [
        {
          encrypted   = true
          volume_type = var.volume_type
          throughput  = var.throughput
          volume_size = var.volume_size
          tags = {
            Name = "my-root-block"
          }
        }
      ]
    }
    bastion = {
      instance_type     = var.instance_type
      availability_zone = element(module.network.aws_all_subnets_az, 1)
      subnet_id         = element(module.network.aws_all_subnets_id_private, 1)
      root_block_device = [
        {
          encrypted   = true
          volume_type = var.volume_type
          volume_size = var.volume_size
        }
      ]
    }
  }
  tags = {
    Name        = local.resource
    project     = var.project
    service     = var.service_name
    environment = var.environment
  }
}

################################################################################
# MULTIPLE EC2 INSTANCES 
################################################################################

module "ec2_multiple" {
  source = "./modules/ec2"

  for_each = local.multiple_instances

  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true

  instance_type          = each.value.instance_type
  availability_zone      = each.value.availability_zone
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = module.network.all_sg
  associate_public_ip_address = var.associate_public_ip_address
  key_name = var.key_name

  tags = local.tags
}
