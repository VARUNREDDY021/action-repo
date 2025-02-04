data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  create = var.create && var.putin_khuylo

  port = coalesce(var.port, (var.engine == "aurora-postgresql" || var.engine == "postgres" ? 5432 : 3306))

  internal_db_subnet_group_name = try(coalesce(var.db_subnet_group_name, var.name), "")
  db_subnet_group_name          = var.create_db_subnet_group && local.create ? try(aws_db_subnet_group.this[0].name, null) : local.internal_db_subnet_group_name

  security_group_name = try(coalesce(var.security_group_name, var.name), "")

  cluster_parameter_group_name = try(coalesce(var.db_cluster_parameter_group_name, var.name), null)
  db_parameter_group_name      = try(coalesce(var.db_parameter_group_name, var.name), null)
  cluster_id = "${var.env}-rds-${var.shortend_region}-postgres-serverless"

  is_serverless = var.engine_mode == "serverless"
}


################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  count = local.create && var.create_db_subnet_group ? 1 : 0

  name        = local.internal_db_subnet_group_name
  description = "For Aurora cluster ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = var.common_tags
}

################################################################################
# Random Password
################################################################################
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

################################################################################
# Cluster
################################################################################

resource "aws_rds_cluster" "this" {
  count = local.create ? 1 : 0
  cluster_identifier                  = local.cluster_id
  allocated_storage                   = var.allocated_storage
  apply_immediately                   = var.apply_immediately
  backup_retention_period             = var.backup_retention_period
  database_name                       = var.is_primary_cluster ? var.database_name : null
  db_cluster_instance_class           = var.db_cluster_instance_class
  db_cluster_parameter_group_name     = var.create_db_cluster_parameter_group ? aws_rds_cluster_parameter_group.this[0].id : var.db_cluster_parameter_group_name
  db_instance_parameter_group_name    = var.allow_major_version_upgrade ? var.db_cluster_db_instance_parameter_group_name : null
  db_subnet_group_name                = local.db_subnet_group_name
  delete_automated_backups            = var.delete_automated_backups
  deletion_protection                 = var.deletion_protection
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  engine                              = var.engine
  engine_mode                         = var.engine_mode
  engine_version                      = var.engine_version
  engine_lifecycle_support            = var.engine_lifecycle_support
  final_snapshot_identifier           = var.final_snapshot_identifier
  iops                                  = var.iops
  master_username                       = aws_ssm_parameter.rds_master_username.value
  master_password                       = aws_ssm_parameter.rds_master_password.value
  performance_insights_enabled          = var.cluster_performance_insights_enabled
  performance_insights_retention_period = var.cluster_performance_insights_retention_period
  port                                  = local.port
  preferred_backup_window               = local.is_serverless ? null : var.preferred_backup_window
  preferred_maintenance_window          = var.preferred_maintenance_window

  dynamic "scaling_configuration" {
    for_each = length(var.scaling_configuration) > 0 && local.is_serverless ? [var.scaling_configuration] : []

    content {
      auto_pause               = try(scaling_configuration.value.auto_pause, null)
      max_capacity             = try(scaling_configuration.value.max_capacity, null)
      min_capacity             = try(scaling_configuration.value.min_capacity, null)
      seconds_until_auto_pause = try(scaling_configuration.value.seconds_until_auto_pause, null)
      seconds_before_timeout   = try(scaling_configuration.value.seconds_before_timeout, null)
      timeout_action           = try(scaling_configuration.value.timeout_action, null)
    }
  }

  dynamic "serverlessv2_scaling_configuration" {
    for_each = length(var.serverlessv2_scaling_configuration) > 0 && var.engine_mode == "provisioned" ? [var.serverlessv2_scaling_configuration] : []

    content {
      max_capacity             = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity             = serverlessv2_scaling_configuration.value.min_capacity
      seconds_until_auto_pause = try(serverlessv2_scaling_configuration.value.seconds_until_auto_pause, null)
    }
  }

  skip_final_snapshot    = var.skip_final_snapshot
  snapshot_identifier    = var.snapshot_identifier
  source_region          = var.source_region
  storage_encrypted      = var.storage_encrypted
  storage_type           = var.storage_type
  tags                   = var.common_tags
  vpc_security_group_ids = var.vpc_security_group_ids

  timeouts {
    create = try(var.cluster_timeouts.create, null)
    update = try(var.cluster_timeouts.update, null)
    delete = try(var.cluster_timeouts.delete, null)
  }
}

################################################################################
# Cluster Instance(s)
################################################################################

resource "aws_rds_cluster_instance" "this" {
  for_each = { for k, v in var.instances : k => v if local.create && !local.is_serverless }

  apply_immediately                     = try(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade            = try(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  availability_zone                     = try(each.value.availability_zone, null)
  cluster_identifier                    = aws_rds_cluster.this[0].id
  copy_tags_to_snapshot                 = try(each.value.copy_tags_to_snapshot, var.copy_tags_to_snapshot)
  db_parameter_group_name               = var.create_db_parameter_group ? aws_db_parameter_group.this[0].id : try(each.value.db_parameter_group_name, var.db_parameter_group_name)
  db_subnet_group_name                  = local.db_subnet_group_name
  engine                                = var.engine
  engine_version                        = var.engine_version
  identifier                            = var.instances_use_identifier_prefix ? null : try(each.value.identifier, "${var.name}-${each.key}")
  identifier_prefix                     = var.instances_use_identifier_prefix ? try(each.value.identifier_prefix, "${var.name}-${each.key}-") : null
  instance_class                        = try(each.value.instance_class, var.instance_class)
  performance_insights_enabled          = try(each.value.performance_insights_enabled, var.performance_insights_enabled)
  # preferred_backup_window - is set at the cluster level and will error if provided here
  preferred_maintenance_window = try(each.value.preferred_maintenance_window, var.preferred_maintenance_window)
  promotion_tier               = try(each.value.promotion_tier, null)
  publicly_accessible          = try(each.value.publicly_accessible, var.publicly_accessible)
  tags                         = var.common_tags

  timeouts {
    create = try(var.instance_timeouts.create, null)
    update = try(var.instance_timeouts.update, null)
    delete = try(var.instance_timeouts.delete, null)
  }
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_rds_cluster_parameter_group" "this" {
  count = local.create && var.create_db_cluster_parameter_group ? 1 : 0

  name        = var.db_cluster_parameter_group_use_name_prefix ? null : local.cluster_parameter_group_name
  name_prefix = var.db_cluster_parameter_group_use_name_prefix ? "${local.cluster_parameter_group_name}-" : null
  description = var.db_cluster_parameter_group_description
  family      = var.db_cluster_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_cluster_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

################################################################################
# DB Parameter Group
################################################################################

resource "aws_db_parameter_group" "this" {
  count = local.create && var.create_db_parameter_group ? 1 : 0

  name        = var.db_parameter_group_use_name_prefix ? null : local.db_parameter_group_name
  name_prefix = var.db_parameter_group_use_name_prefix ? "${local.db_parameter_group_name}-" : null
  description = var.db_parameter_group_description
  family      = var.db_parameter_group_family

  dynamic "parameter" {
    for_each = var.db_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.common_tags
}

resource "aws_ssm_parameter" "rds_url" {
   name        = "${var.env}-${var.shortend_region}-${var.project}.db.url"
   type        = "SecureString"
   value       = aws_rds_cluster.this[0].endpoint  # Add index here
   description = "${var.env} ${var.project} RDS Endpoint"
   tags = merge(
     var.common_tags
   )
}