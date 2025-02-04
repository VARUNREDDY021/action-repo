# variable "bucket_name" {
#   type = string
# }
variable "env" {
  type = string
}
variable "shortend_region" {
  type = string
}
# variable "s3_key" {
#   type = string
# }

variable "subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for Lambda VPC configuration"
  type        = list(string)
}
variable "common_tags" {}