# Environment Prefix for Lambda Functions
variable "env"{
  description = "The environment prefix for the Lambda functions (e.g., dev, staging, prod)"
  type        = string
}

# List of Lambda Function Names
variable "lambda_function_names" {
  description = "List of Lambda function names"
  type        = list(string)
}

# AWS Region
variable "region" {
  description = "AWS region for resource deployment"
  type        = string
}

# S3 Bucket for Lambda Code and Layers
# variable "s3_bucket" {
#   description = "S3 bucket where Lambda function code and layers are stored"
#   type        = string
# }

# # S3 Key for Lambda Function Code
# variable "s3_key_function" {
#   description = "S3 key for Lambda function code"
#   type        = string
# }

variable "shortened_region" {
  description = "AWS region for resource deployment"
  type        = string
}

# Environment Variables for Lambda Functions
variable "environment_variables" {
  description = "Map of environment variables for the Lambda functions"
  type        = map(string)
  default = {}
}
variable "odds_calculations_lambda" {
  type = string
}
variable "subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for Lambda VPC configuration"
  type        = list(string)
}
variable "common_tags" {}