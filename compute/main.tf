# Reference the remote state from the first module
data "terraform_remote_state" "vpc" {
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "vpc/terraform.tfstate"
    region = "me-central-1"
  }
}

data "terraform_remote_state" "ec2_sg" {
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "vpc/terraform.tfstate"
    region = "me-central-1"
  }
}

###############################################################################
# ECR
###############################################################################
module "ecs-repo" {
  for_each                        = toset(["api", "notification", "oddsmatrix"])
  source                          = "../modules/ecr"
  repository_name                 = "${var.project}-${each.key}"
  repository_image_tag_mutability = "MUTABLE"
  common_tags                     = merge(
    local.common_tags,
    {
      "AWSService" = "ECR"
    }
  )
}

###############################################################################
# EKS
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.0"

  cluster_name    = "${var.env}-${var.shortend_region}-eks-cluster"
  cluster_version = var.cluster_version
  cluster_endpoint_public_access  = true
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    # aws-ebs-csi-driver = { 
    #   most_recent = true
    # }
  }

  vpc_id                   = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids               = data.terraform_remote_state.vpc.outputs.private_subnets
  control_plane_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  eks_managed_node_groups = {
    eks_private_nodegroup = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type]

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
      subnet_ids   = data.terraform_remote_state.vpc.outputs.private_subnets  # Private subnet for this node group
    }

    eks_public_nodegroup = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.instance_type]

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
      subnet_ids   = data.terraform_remote_state.vpc.outputs.public_subnets  # Public subnet for this node group
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    "karpenter.sh/discovery" = "${var.env}-${var.shortend_region}-eks-cluster"
  }
  tags = merge(
    local.common_tags,
    {
      "AWSService" = "EKS"
    }
  )
}

module "ec2" {
  depends_on        = [data.terraform_remote_state.vpc]
  source            = "../modules/ec2"
  project           = var.project
  env               = var.env
  instance_type     = "t2.micro"
  disk_size         = "30"
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id         = data.terraform_remote_state.vpc.outputs.public_subnets[0]
  security_groups   = [data.terraform_remote_state.ec2_sg.outputs.ec2_sg_id]
  ec2_ami           = var.ec2_ami
  key_name          = var.key_name
  # user_data       = var.user_data
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "EC2"
    }
  )
}