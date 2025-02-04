# Reference the remote state from the first module
data "terraform_remote_state" "vpc" {
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "vpc/terraform.tfstate"
    region = "me-central-1"
  }
}
data "terraform_remote_state" "comm_sg"{
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "vpc/terraform.tfstate"
    region = "me-central-1"
  }
}

data "terraform_remote_state" "odds_matrix_raw_data" {
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "storage/terraform.tfstate"
    region = "me-central-1"
  }
}
data "terraform_remote_state" "odds_matrix_lambda_code" {
  backend = "s3"  # Can be changed based on your backend (e.g., s3, gcs, etc.)
  
  config = {
    bucket = "env-project-703671907665-tf-state"
    key    = "storage/terraform.tfstate"
    region = "me-central-1"
  }
}

#########################################################################
#ODDs_MATRIX_LAMBDA
########################################################################
module "odds_matrix_lambda_code" {
  source                  = "../modules/odds_lambda"
  env                     = var.env
  shortend_region         = var.shortend_region
  common_tags             = merge(local.common_tags)
  subnet_ids              = data.terraform_remote_state.vpc.outputs.private_subnets
  security_group_ids      = [data.terraform_remote_state.comm_sg.outputs.comm_sg_id]
}

#########################################################################
#ODDs_MATRIX_LAMBDA_GAME_SNS
########################################################################
module "odds_matrix_lambda_game_sns" {
  source                  = "../modules/odds_game_lambda"
  env                     = var.env
  lambda_function_names   = ["odds_results_basketball", "odds_results_football"]
  region                  = var.region  
  shortened_region        = var.shortend_region
  common_tags             = merge(local.common_tags)
  odds_calculations_lambda = module.odds_matrix_lambda_code.odds_calculation
  subnet_ids             = data.terraform_remote_state.vpc.outputs.private_subnets            # Pass subnet IDs
  security_group_ids     = [data.terraform_remote_state.comm_sg.outputs.comm_sg_id]    # Pass security group IDs
}