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
variable "s3_bucket" {
  description = "S3 bucket where Lambda function code and layers are stored"
  type        = string
}

# S3 Key for Lambda Function Code
variable "s3_key_function" {
  description = "S3 key for Lambda function code"
  type        = string
}

# S3 Key for Lambda Layer Code
variable "s3_key_layer" {
  description = "S3 key for Lambda layer code"
  type        = string
}

# Environment Variables for Lambda Functions
variable "environment_variables" {
  description = "Map of environment variables for the Lambda functions"
  type        = map(string)
  default     = {
    API_KEY  = ""              # API Key (to be set per environment)
    BASE_URL = ""              # Base URL for API calls
    REGION   = ""     # Execution region for the Lambda function
  }
}
variable "common_tags" {}
