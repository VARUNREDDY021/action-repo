resource "aws_iam_role" "lambda_role" {
  name               = "${var.env}-${var.shortend_region}-lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
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
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.env}-${var.shortend_region}-lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # DynamoDB permissions
      {
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # SNS permissions
      {
        Action   = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:ListSubscriptions",
          "sns:ListSubscriptionsByTopic"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # RDS permissions
      {
        Action   = [
          "rds:DescribeDBInstances",
          "rds:ExecuteStatement",
          "rds:BatchExecuteStatement"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # S3 permissions
      {
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # Lambda permissions (to invoke another Lambda function)
      {
        Action   = [
          "lambda:InvokeFunction",
          "lambda:InvokeAsync"
        ]
        Effect   = "Allow"
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

resource "aws_lambda_function" "initial_dump_recevier" {
  function_name = "${var.env}-lambda-${var.shortend_region}-Initial-dump-receiver"
  role          = aws_iam_role.lambda_role.arn
  handler       = "OddsMatrix.Lambda.InitialDump::OddsMatrix.Lambda.InitialDump.Function::FunctionHandler"
  runtime       = "dotnet8"    

  filename      = "${path.module}/lambda_code/InitialDump.zip"
  timeout       = 60

  # VPC Configuration
  vpc_config {
    subnet_ids          = var.subnet_ids
    security_group_ids  = var.security_group_ids
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"       = "${var.env}-lambda-${var.shortend_region}-Initial-dump-receiver"
      "AWSService" = "Lambda"
    })
  )
}

resource "aws_lambda_function" "Odds_Calculation" {
  function_name = "${var.env}-lambda-${var.shortend_region}-odds_calculations"
  role          = aws_iam_role.lambda_role.arn
  handler       = "OddsMatrix.Lambda.Oddscalculation::OddsMatrix.Lambda.InitialDump.Function::FunctionHandler"
  runtime       = "dotnet8"    

  filename      = "${path.module}/lambda_code/OddsCalculation.zip"
  timeout       = 60

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.file_processing_status.name
    }
  }

  # VPC Configuration
  vpc_config {
    subnet_ids          = var.subnet_ids
    security_group_ids  = var.security_group_ids
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"       = "${var.env}-lambda-${var.shortend_region}-odds_calculation"
      "AWSService" = "Lambda"
    })
  )
}

resource "aws_sns_topic" "start_odds_calculation" {
  name = "${var.env}-lambda-${var.shortend_region}-start-odds-calculation"  # Specify the name of the SNS topic
}

resource "aws_sns_topic_subscription" "start_odds_calculation" {
  topic_arn = aws_sns_topic.start_odds_calculation.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.Odds_Calculation.arn

  # This will enable SNS to trigger the Lambda function
  raw_message_delivery = false
}

# Step 3: Grant SNS permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  function_name = aws_lambda_function.Odds_Calculation.function_name
  source_arn    = aws_sns_topic.start_odds_calculation.arn
}

resource "aws_dynamodb_table" "file_processing_status" {
  name     = "${var.env}-dynamodb-${var.shortend_region}-file_processing_status"
  billing_mode = "PROVISIONED"
  hash_key     = "batchid"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "batchid"
    type = "S"  # String type
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"       = "${var.env}-file_processing_status-dynamodb"
      "AWSService" = "DynamoDB"
    })
  )
}