output "lambda_function_names" {
  value = aws_lambda_function.lambda_function[*].function_name
}

output "sns_topic_arns" {
  value = aws_sns_topic.lambda_sns[*].arn
}

output "lambda_layer_versions" {
  value = aws_lambda_layer_version.lambda_layer[*].arn
}