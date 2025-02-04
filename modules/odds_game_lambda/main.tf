# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_exec_role" {
  for_each = toset(var.lambda_function_names)
  name     = "${var.env}-iam-${var.shortened_region}-${each.value}-role"

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
  name     = "${var.env}-iam-${var.shortened_region}-${each.value}-policy"
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
        Action = "sns:Publish",  # Add SNS permission if Lambda needs to publish to SNS
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = "dynamodb:PutItem",  # DynamoDB Permissions for Lambda functions
        Effect = "Allow",
        Resource = "*"
      },
      {
        # EC2 permissions for creating and managing network interfaces for VPC Lambda
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Lambda Functions with VPC Configuration
# Lambda Functions with Local ZIP File
resource "aws_lambda_function" "lambda_function" {
  for_each      = toset(var.lambda_function_names)
  function_name = "${var.env}-lambda-${var.shortened_region}-${each.value}_function"

  # Reference to the local ZIP file for Lambda code
  filename       = "${path.module}/lambda_code/lambda_code.zip"  # Adjust the path if necessary

  handler        = "OddsMatrix.Lambda.OddsCalculationResultsHandler::OddsMatrix.Lambda.OddsCalculationResultsHandler.Function::FunctionHandler"
  runtime        = "dotnet8"

  environment {
    variables = merge(
      var.environment_variables,
      {
        DYNAMODB_TABLE_ARN = aws_dynamodb_table.lambda_dynamodb_table[each.key].arn
        DYNAMODB_TABLE_NAME = aws_dynamodb_table.lambda_dynamodb_table[each.key].name
      }
    )
  }

  role = aws_iam_role.lambda_exec_role[each.key].arn
  
  # VPC Configuration
  vpc_config {
    subnet_ids          = var.subnet_ids
    security_group_ids  = var.security_group_ids
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"       = "${var.env}-${each.value}"
      "AWSService" = "Lambda"
    })
  )
}


# SNS Topic for each Lambda Function
resource "aws_sns_topic" "lambda_sns" {
  for_each = toset(var.lambda_function_names)
  name     = "${var.env}-sns-${var.shortened_region}-${each.value}_topic"
  
  tags = merge(
    var.common_tags,
    tomap({
      "Name"       = "${var.env}-${each.value}-sns"
      "AWSService" = "Sns"
    })
  )
}

# SNS Subscription to Lambda Function
resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  for_each  = toset(var.lambda_function_names)
  topic_arn = aws_sns_topic.lambda_sns[each.key].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_function[each.key].arn
}

resource "aws_sns_topic_subscription" "lambda_sns_subscription_odds_calculation" {
  for_each  = toset(var.lambda_function_names)
  topic_arn = aws_sns_topic.lambda_sns[each.key].arn
  protocol  = "lambda"
  endpoint  = var.odds_calculations_lambda
}

# Lambda Permission for SNS
resource "aws_lambda_permission" "sns_invoke_permission" {
  for_each     = toset(var.lambda_function_names)
  statement_id = "${each.value}_sns_permission"
  action       = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function[each.key].function_name
  principal    = "sns.amazonaws.com"
  source_arn   = aws_sns_topic.lambda_sns[each.key].arn

  depends_on = [
    aws_sns_topic_subscription.lambda_sns_subscription
  ]
}

# DynamoDB Table for each Lambda Function
resource "aws_dynamodb_table" "lambda_dynamodb_table" {
  for_each = toset(var.lambda_function_names)
  name     = "${var.env}-dynamodb-${var.shortened_region}-${each.value}_table"
  billing_mode = "PROVISIONED"
  hash_key     = "matchid"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "matchid"
    type = "S"  # String type
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"       = "${var.env}-${each.value}-dynamodb"
      "AWSService" = "DynamoDB"
    })
  )
}

# DynamoDB Permissions for Lambda
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  for_each = toset(var.lambda_function_names)
  name     = "${var.env}-iam-${var.shortened_region}-${each.value}-dynamodb-policy"
  role     = aws_iam_role.lambda_exec_role[each.key].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "dynamodb:PutItem",  # Permissions for writing to DynamoDB
        Effect = "Allow",
        Resource = aws_dynamodb_table.lambda_dynamodb_table[each.key].arn
      },
      {
        Action = "dynamodb:GetItem",  # Permissions for reading from DynamoDB
        Effect = "Allow",
        Resource = aws_dynamodb_table.lambda_dynamodb_table[each.key].arn
      },
      {
        Action = "dynamodb:Query",  # Permissions for querying DynamoDB
        Effect = "Allow",
        Resource = aws_dynamodb_table.lambda_dynamodb_table[each.key].arn
      }
    ]
  })
}