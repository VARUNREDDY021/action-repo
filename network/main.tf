data "aws_caller_identity" "current" {}
###############################################################################
# VPC
###############################################################################
module "vpc" {
  source = "../modules/vpc"
  env    = local.env
  project = local.project
  vpc_name = "${local.env}-${var.shortend_region}"
  vpc_cidr = local.vpc_cidr
  az_list  = ["us-east-1a", "us-east-1b"]
  single_nat_gw = true
  customer = local.Customer
  common_tags = local.common_tags
  
  # Adding public and private subnet tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery" = "${var.env}-eks-${var.shortend_region}-cluster"
  }
}


###############################################################################
# Security-Groups
###############################################################################
module "comm_sg" {
  source      = "../modules/sg/comm_sg"
  env         = var.env
  project     = var.project
  shortend_region = var.shortend_region
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "${var.env}-${var.shortend_region}-comm-sg"
    }
  )
  vpc_id      = module.vpc.vpc_id
}

module "ec2_sg" {
  source      = "../modules/sg/ec2_sg"
  project     = var.project
  env         = var.env
  shortend_region = var.shortend_region
  vpc_id      = module.vpc.vpc_id
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "${var.env}-${var.shortend_region}-comm-sg"
    }
  )
}

