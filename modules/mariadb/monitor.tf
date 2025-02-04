locals {
    account_id = data.aws_caller_identity.current
    thresholds = {
        critical_cpu_consumedthreshold = min(max(var.critical_cpu_consumedthreshold, 0), 100)
        critical_memory_consumedthreshold = min(max(var.critical_memory_consumedthreshold, 0), 100)
    }
}

module "critical_cpu_consumedthreshold" {
  source = "../cloudwatch"
  alarm_name          = "${var.project}-rds-critical-alert-cpu-consumed-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cpu_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.cpu_period
  statistic           = "Average"
  threshold           = local.thresholds["critical_cpu_consumedthreshold"]
  alarm_description   = "${var.project} - CPU Utilization is High"
  ok_actions          = var.ok_actions
  actions_enabled     = var.actions_enabled
  alarm_actions       = var.alarm_actions
  treat_missing_data = var.treat_missing_data
  dimensions          = {DBClusterIdentifier = local.cluster_id}
  tags                = var.common_tags
}

module "critical_memory_consumedthreshold" {
  source = "../cloudwatch"
  alarm_name          = "${var.project}-rds-critical-alert-memory-consumed-high"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.memory_evaluation_periods
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = var.memory_period
  statistic           = "Average"
  threshold           = local.thresholds["critical_memory_consumedthreshold"]
  alarm_description   = "${var.project} - Memory Utilization is High"
  ok_actions          = var.ok_actions
  actions_enabled     = var.actions_enabled
  alarm_actions       = var.alarm_actions
  treat_missing_data = var.treat_missing_data
  dimensions          = {DBClusterIdentifier = local.cluster_id}
  tags                = var.common_tags
}

module "db_connections" {
  source = "../cloudwatch"
  alarm_name          = "${var.project}-rds-critical-alert-db-connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.dbconnections_evaluation_periods
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = var.dbconnections_period
  statistic           = "Average"
  threshold           = var.dbconnections_threshold
  alarm_description   = "${var.project} - DB Connections are exceeded"
  ok_actions          = var.ok_actions
  actions_enabled     = var.actions_enabled
  alarm_actions       = var.alarm_actions
  dimensions          = {DBClusterIdentifier = "DatabaseConnections"}
  treat_missing_data  = "notBreaching"
  tags                = var.common_tags
}