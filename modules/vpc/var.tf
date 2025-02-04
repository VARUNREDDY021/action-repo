variable "env" {
  type = string
}
variable "customer" {
  type = string
}
variable "vpc_name" {
  type = string
}

variable "common_tags" {
  type = map(any)
}
variable "vpc_cidr" {
  type = string
}

variable "az_list" {
  type = list
}

# variable "vpce_interfaces" {
#   type    = list
#   default = ["monitoring", "logs", "kinesis-streams", "sns", "sqs", "kms", "ssm", ]
# }

# variable "vpce_gateways" {
#   type    = list
#   default = ["s3", "dynamodb"]
# }

variable "single_nat_gw" {
  type    = string
  default = "false"
}

# variable "magento_allow_ssh_ip" {
#   type = list(string)
# }

# variable "wordpress_allow_ssh_ip" {
#   type = list(string)
# }

variable "project" {}
variable "private_subnet_tags" {}
variable "public_subnet_tags" {}
variable "create_nat_gw" {
  description = "Whether to create NAT Gateways (false to skip)"
  type        = bool
  default     = false
}