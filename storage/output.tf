output "odds_matrix_raw_data" {
  value = module.odds_matrix_raw_data.s3_bucket
}
output "odds_s3_lambda_code" {
  value = module.odds_matrix_lambda_code.s3_bucket
}
output "odds_matrix_lambda_code_folders" {
  value = module.odds_matrix_lambda_code.folders
}