##################################             ###############################
#                                      ENV                                   #
##################################             ###############################
variable "environment" {
  type = string
  description = "Deployment environment, Options: dissaster-reccovery, dev"
}

variable "project" {
  type = string
  description = "Desired name for product resources identification."
}

variable "service_name" {
  type = string
  description = "Service name description."
}

##################################             ###############################
#                                     EC2                                    #
##################################             ###############################

variable "associate_public_ip_address" {
  type = string
  description = " Associate an public ipv4 ip to instance"
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "throughput" {
  type         = string
  description  = " Instance volume throughput"
  default      = "gp3"
}

variable "volume_size" {
  type         = string
  description  = " Instance volume size"
  default      = "gp3"
}

variable "instance_type" {
  type        = string
  description = "Instance Type, default t2 micro"
  default     = "t2.micro"
}
