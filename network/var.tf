###############################################################################
# Environment
###############################################################################
variable "region" {
    type = string
}

variable "env" {
    type = string
}
variable "project" {
    type = string
}
variable "aws_account_id" {
    type = string
}
variable "application" {
    type = string
}
variable "shortend_region" {
  type = string
  default = ""
}
variable "vpc_cidr" {
    type = string
}
variable "customer"{
    type = string
}
variable "public_subnet_tags" {
  description = "Tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Tags for private subnets"
  type        = map(string)
  default     = {}
}