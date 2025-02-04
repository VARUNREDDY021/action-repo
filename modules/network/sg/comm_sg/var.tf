variable "project" {}
variable "env" {}
variable "common_tags" {
    type = map(any)
}
variable "vpc_id" {}
variable "alb_sg" {}
