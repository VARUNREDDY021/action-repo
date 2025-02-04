###############################################################################
# Provider
###############################################################################
provider "aws" {
    region              = var.region
    allowed_account_ids = [var.aws_account_id]
}

terraform {
  backend "s3" {
    bucket = "env-project-703671907665-tf-state"
    region = "me-central-1"
    key    = "compute/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = tomap({
    "Environment"       = var.env,
    "Application"       = var.application,
    "Region"            = "us-east-1",
    "Owner"             = "developer",
    "Cost Center"       = "${var.env}-Cost",
    "Project"           = var.project,
    "ManagedBy"         = "Terraform"
  })
}


