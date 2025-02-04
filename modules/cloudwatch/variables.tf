variable "enabled" {
   type = bool
   default = true
}
variable "alarm_name" {}
variable "comparison_operator" {}
variable "evaluation_periods" {}
variable "metric_name" {}
variable "namespace" {}
variable "period" {}
variable "statistic" {}
variable "threshold" {}
variable "alarm_description" {}
variable "ok_actions" {}
variable "actions_enabled" {
    default = "true"
}
variable "alarm_actions" {}
variable "insufficient_data_actions" {
    default = []
}
variable "dimensions" {}
variable "treat_missing_data" {
    default = "notBreaching"
}
variable "tags" {
    type = map(string)
    default = {}
}
variable "datapoints_to_alarm" {
    default = 1
}