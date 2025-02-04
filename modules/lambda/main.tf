# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_exec_role" {
  for_each = toset(var.lambda_function_names)
  name     = "${each.value}_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = var.common_tags
}
# IAM Role Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_exec_policy" {
  for_each = toset(var.lambda_function_names)
  name     = "${each.value}_lambda_exec_policy"
  role     = aws_iam_role.lambda_exec_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "application-autoscaling:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = ["s3:GetObject"],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}/${var.s3_key_function}",
          "arn:aws:s3:::${var.s3_bucket}/${var.s3_key_layer}"
        ]
      }
    ]
  })
}

# Lambda Layers
resource "aws_lambda_layer_version" "lambda_layer" {
  for_each            = toset(var.lambda_function_names)
  s3_bucket           = var.s3_bucket
  s3_key              = var.s3_key_layer
  layer_name          = "${each.value}_layer"
  compatible_runtimes = ["python3.11"]
}

# Lambda Functions
resource "aws_lambda_function" "lambda_function" {
  for_each      = toset(var.lambda_function_names)
  function_name = each.value
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key_function
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  layers        = [aws_lambda_layer_version.lambda_layer[each.key].arn]

  environment {
    variables = var.environment_variables
  }

  role = aws_iam_role.lambda_exec_role[each.key].arn
  tags = var.common_tags
}

# SNS Topic for each Lambda Function
resource "aws_sns_topic" "lambda_sns" {
  for_each = toset(var.lambda_function_names)
  name     = "${each.value}_sns_topic"
  tags = var.common_tags
}

# SNS Subscription to Lambda Function
resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  for_each  = toset(var.lambda_function_names)
  topic_arn = aws_sns_topic.lambda_sns[each.key].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_function[each.key].arn
}

# Lambda Permission for SNS
resource "aws_lambda_permission" "sns_invoke_permission" {
  for_each       = toset(var.lambda_function_names)
  statement_id   = "${each.key}_sns_permission"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda_function[each.key].function_name
  principal      = "sns.amazonaws.com"
  source_arn     = aws_sns_topic.lambda_sns[each.key].arn
}