variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags definition."
}


variable "ami"{
  type = string
  description = "Ami type, default amazon linux 2"
  default = "ami-09d3b3274b6c5d4aa"
}

variable "ami_ssm_parameter" {
  description = "SSM parameter name for the AMI ID. For Amazon Linux AMI SSM parameters see [reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html)"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

variable "instance_type" {
  type = string
  description = "Instance Type, default t2 micro"
  default = "t2.micro"
}

variable "create" {
  description = "Whether to create an instance"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "The user data to provide when launching the instance. Do not pass gzip-compressed data via this argument; see user_data_base64 instead."
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Can be used instead of user_data to pass base64-encoded binary data directly. Use this instead of user_data whenever the value is not a valid UTF-8 string. For example, gzip-encoded user data must be base64-encoded and passed via this argument to avoid corruption."
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "When used in combination with user_data or user_data_base64 will trigger a destroy and recreate when set to true. Defaults to false if not set."
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = null
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}


variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = true
}

variable "private_ip" {
  description = "Private IP address to associate with the instance in a VPC"
  type        = string
  default     = null
}

variable "secondary_private_ips" {
  description = "A list of secondary private IPv4 addresses to assign to the instance's primary network interface (eth0) in a VPC. Can only be assigned to the primary network interface (eth0) attached at instance creation, not a pre-existing network interface i.e. referenced in a `network_interface block`"
  type        = list(string)
  default     = null
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = false
}

