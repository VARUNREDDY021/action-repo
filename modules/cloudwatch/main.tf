resource "aws_cloudwatch_metric_alarm" "alarm" {
  count               = var.enabled == true ? 1: 0
  alarm_name          = var.alarm_name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = var.alarm_description
  ok_actions          = var.ok_actions
  actions_enabled     = var.actions_enabled
  alarm_actions       = var.alarm_actions
  datapoints_to_alarm = var.datapoints_to_alarm
  insufficient_data_actions = var.insufficient_data_actions
  dimensions          = var.dimensions
  treat_missing_data = var.treat_missing_data
  tags                = var.tags
}