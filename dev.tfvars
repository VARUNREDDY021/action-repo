###############################################################################
# Environment
###############################################################################
region         = "us-east-1"
aws_account_id = "703671907665"
env = "dev"
project = "logger"
application = "app"
vpc_cidr = "10.0.0.0/16"
customer = "new"
shortend_region = "ue1"
###############################################################################
# EKS
###############################################################################
cluster_name = "logger"
cluster_version = "1.31"
min_size = "1"
max_size = "2"
desired_size = "1"
instance_type = "t3.medium"
###############################################################################
# EC2
###############################################################################
ec2_ami = "ami-0ca9fb66e076a6e32"
key_name = "varun-reddy"
###############################################################################
# RDS
###############################################################################
db_instance_type          = "db.t3.medium"
db_instance_count         = "1"
###############################################################################
# MariaDB-OddsMatrix
###############################################################################
mariadb_allocated_storage = "100"
mariadb_instance_type = "db.t3.micro"
storage_type = "gp2"
iops = "1000"
storage_throughput = "125"
###############################################################################
# RDS_SERVERLESS
###############################################################################
serverless_instance_type          = "db.serverless"
min_capacity                      = "2"
max_capacity                      = "2"
seconds_until_auto_pause          = "300"
###############################################################################
# ODDS_MATRIX_LAMBDA_S3
###############################################################################


