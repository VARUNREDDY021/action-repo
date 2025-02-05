# Reference the remote state from the first module
data "terraform_remote_state" "vpc" {
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}
data "terraform_remote_state" "comm_sg"{
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state-test1"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "ec2_sg"{
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state-test1"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}


###############################################################################
# ODDS MATRIX - S3_BUCKET
###############################################################################
module "odds_matrix_raw_data" {
  source = "../modules/odds_s3_raw_data"
  bucket_name = "${var.env}-s3-${var.shortend_region}-odds-matrix-raw-data"
  folders = ["entites", "updates"]
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "S3"
    }
  )
}

module "odds_matrix_lambda_code" {
  source = "../modules/odds_s3_lambda_code"
  bucket_name = "${var.env}-s3-${var.shortend_region}-odds-matrix-lambda-code"
  folders = ["process_initial_data", "odds_calculation", "push_updates_non_outcome", "receive_push_updates", "push_updates_outcome", "odds_results_football"]
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "S3"
    }
  )
}

###############################################################################
# SNS-TOPIC
###############################################################################
module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"

  name  = "${var.env}-${var.project}-sns-topic"
  subscriptions = {
    email_subscription = {
      protocol = "email"
      endpoint = "vangalapradeep1905@gmail.com"
    }
  }

  tags = merge(
    local.common_tags,
    {
      "AWSService" = "SNS"
    }
  )
}

###############################################################################
# Postgres-RDS
###############################################################################
module "db" {
  depends_on = [data.terraform_remote_state.vpc]
  source = "../modules/rds"
  project = var.project
  env  = var.env
  vpc_security_group_ids = [data.terraform_remote_state.comm_sg.outputs.comm_sg_id,data.terraform_remote_state.ec2_sg.outputs.ec2_sg_id]
  instance_count = var.db_instance_count
  instance_type = var.db_instance_type
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  apply_immediately = "true"
  alarm_actions = [module.sns_topic.topic_arn]
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "RDS_POSTGRES"
    }
  )
}

###############################################################################
# MariaDB-OddsMatrix
###############################################################################
module "mariadb" {
  depends_on = [data.terraform_remote_state.vpc]
  source = "../modules/mariadb"
  project = var.project
  env  = var.env
  vpc_security_group_ids = [data.terraform_remote_state.comm_sg.outputs.comm_sg_id,data.terraform_remote_state.ec2_sg.outputs.ec2_sg_id]
  # instance_count = var.db_instance_count
  instance_type = var.mariadb_instance_type
  allocated_storage = var.mariadb_allocated_storage
  storage_throughput = var.storage_throughput
  storage_type = var.storage_type
  iops = var.iops
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  apply_immediately = "true"
  alarm_actions = [module.sns_topic.topic_arn]
  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "RDS_MARIADB"
    }
  )
}

###############################################################################
# Postgres-DAASH-SERVERLESS
###############################################################################
data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "14.12"
}

module "aurora_postgresql" {
  source                            = "../modules/rds_serverless"
  env                               = var.env
  project                           = var.env
  shortend_region                   = var.shortend_region
  name                              = "${var.env}-rds-${var.shortend_region}-postgres-serverless"
  engine                            = "aurora-postgresql"
  engine_mode                       = "provisioned"
  engine_version                    = data.aws_rds_engine_version.postgresql.version
  instance_class                    = "db.serverless"
  storage_encrypted                 = true
  vpc_id                            = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids                        = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_rules              = [data.terraform_remote_state.comm_sg.outputs.comm_sg_id]
  db_subnet_group_name              = "${var.env}-rds-${var.shortend_region}-postgres-serverless"
  enabled_cloudwatch_logs_exports   = ["postgresql", "iam-db-auth-error"]
  alarm_actions                     = [module.sns_topic.topic_arn]
  performance_insights_enabled      = false
  skip_final_snapshot               = true
  apply_immediately                 = "true"
  serverlessv2_scaling_configuration = {
    min_capacity             = 0
    max_capacity             = 10
    seconds_until_auto_pause = 3600
  }
  instances = {
    one = {}
  }

  common_tags = merge(
    local.common_tags,
    {
      "AWSService" = "RDS_SERVERLESS"
    }
  )
}


