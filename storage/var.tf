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
# POSTGRES-RDS
###############################################################################
variable "db_instance_type" {
  default = ""
}

variable "db_instance_count" {
  default = ""
}
###############################################################################
# MariaDB-OddsMatrix
###############################################################################
variable "mariadb_instance_type" {
  default = ""
}
variable "mariadb_allocated_storage" {
  default = ""
}
variable "storage_type" {
  default = ""
}
variable "iops" {
  default = ""
}
variable "storage_throughput" {
  default = ""
}
###############################################################################
# POSTGRES-RDS
###############################################################################
