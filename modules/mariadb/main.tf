
locals {
  engine = "mariadb"
  engine_mode = "provisioned"
  cluster_id = "${var.env}-rds-${var.shortend_region}-${var.project}-db-cluster"
}

data "aws_caller_identity" "current" {}

##################
#Generate Password
##################

# # RDS Password
# Random Password
 resource "random_password" "rds_password" {
   length           = 16
   special          = false
 }

 resource "aws_ssm_parameter" "rds_master_username" {
   name        = "${var.env}-${var.shortend_region}-${var.project}.db.admin.username"
   type        = "SecureString"
   value       = var.master_username
   description = "${var.env} ${var.project} RDS Master Username"
   tags = merge(
     var.common_tags
   )
 }

resource "aws_ssm_parameter" "rds_master_password" {
  name        = "${var.env}-${var.shortend_region}-${var.project}.db.admin.password"
  type        = "SecureString"
  value       = random_password.rds_password.result
  description = "${var.env} ${var.project} RDS Master Password"
  tags = merge(
    var.common_tags
  )
}

##########################################
#  MariaDB Cluster
##########################################
resource "random_id" "uid" {
  byte_length = 8
}

resource "aws_db_instance" "pod_mariadb" {
  identifier             = local.cluster_id
  allocated_storage      = var.allocated_storage
  iops                   = var.iops
  storage_type           = var.storage_type
  storage_throughput     = var.storage_throughput  
  # db_name              = var.db_name
  engine                 = local.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_type
  username               = aws_ssm_parameter.rds_master_username.value
  password               = aws_ssm_parameter.rds_master_password.value
  skip_final_snapshot    = var.skip_final_snapshot
  deletion_protection    = var.deletion_protection
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false
  storage_encrypted = var.storage_encrypted
  apply_immediately = var.apply_immediately

  tags = merge(
    var.common_tags
  )
}

# RDS DB Subnet Group
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.env}-${var.shortend_region}-${var.project}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.common_tags,
  )
}

resource "aws_ssm_parameter" "rds_url" {
   name        = "${var.env}-${var.shortend_region}-${var.project}.db.url"
   type        = "SecureString"
   value       = aws_db_instance.pod_mariadb.endpoint
   description = "${var.env} ${var.project} RDS Endpoint"
   tags = merge(
     var.common_tags
   )
 }