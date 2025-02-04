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
}
###############################################################################
# EC2
###############################################################################
variable "ec2_ami" {
  default = ""
}
variable "key_name" {}
###############################################################################
# Cluster
###############################################################################
variable "cluster_name" {
    type = string
}
variable "cluster_version" {
    type = string
}
variable "min_size" {
    type = string
}
variable "max_size" {
    type = string
}
variable "desired_size" {
    type = string
}
variable "instance_type" {
    type = string
}