output "lambda_function_names" {
  value = [for fn in aws_lambda_function.lambda_function : fn.function_name]
}

output "sns_topic_arns" {
  value = [for topic in aws_sns_topic.lambda_sns : topic.arn]
}