variable "ec2_ami" {
  type = string
}
variable "vpc_id" {}
variable "instance_type" {
}
variable "associate_public_ip_address" {
  type = bool
  default = true
}
variable "disk_size" {
}
variable "env" {
}
variable "project" {  
}
variable "common_tags" {}
variable "security_groups" {
    type = list
}

# variable "user_data" {
# }
variable "key_name" {
  
}
variable "subnet_id" {}