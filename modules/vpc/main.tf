locals {
  # Create list of route table ids
  private_rt_ids = [
    for key, value in aws_route_table.private_rt : value.id
  ]
  public_rt_ids = [
    aws_route_table.public_rt.id
  ]
  route_tables = [
    for key, value in concat(local.private_rt_ids, local.public_rt_ids) : {
      key   = key
      rt_id = value
    }
  ]

  any_port     = 0
  https_port   = "443"
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]

}

# Get Current Region
data "aws_region" "current" {}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    tomap({
      "Name"="${var.vpc_name}-vpc",
})
  )
}

#VPC Flow logs
# TODO: Enable VPC FLow Logs

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.common_tags,
    tomap({
      "Name"="${var.vpc_name}_igw",
})
  )
}

# NAT Gateways
resource "aws_eip" "nat_gw" {
  count = var.single_nat_gw ? 1 : length(var.az_list)
  vpc   = true

  tags = merge(
    var.common_tags,
    tomap({
      "Name"="${var.vpc_name}_natgw",
})
  )
}

resource "aws_nat_gateway" "nat_gw" {
  count         = var.single_nat_gw ? 1 : length(var.az_list)
  allocation_id = aws_eip.nat_gw.*.id[count.index]
  subnet_id     = aws_subnet.public_subnet.*.id[count.index]

  tags = merge(
    var.common_tags,
    tomap({
      "Name"="${var.vpc_name}_nat_gw_${count.index + 1}",
      "AWSService"="NAT-Gateway"
})
  )

  depends_on = [aws_internet_gateway.igw]
}

# Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"="${var.vpc_name}_public_rt",
      "Tier"="Public",
      "AWSService"="Route_Table"
})
  )
}

resource "aws_subnet" "public_subnet" {
  count                   = length(var.az_list)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = var.az_list[count.index]

  tags = merge(
    var.common_tags,
    var.public_subnet_tags,
    tomap({
      "Name"="${var.vpc_name}_public_subnet_${count.index + 1}",
      "Tier"="Public",
      "AWSService"="Subnet"
})
  )
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

# Private Subnets
resource "aws_route_table" "private_rt" {
  count = length(aws_nat_gateway.nat_gw)

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.*.id[count.index]
  }

  tags = merge(
    var.common_tags,
    tomap({
      "Name"="${var.vpc_name}_private_rt_${count.index + 1}",
      "Tier"="Private",
      "AWSService"="Route_Table"
      "NatGateway" = "${var.create_nat_gw}"
})
  )
}

resource "aws_subnet" "private_subnet" {
  count                   = length(var.az_list)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, count.index + 1)
  map_public_ip_on_launch = false
  availability_zone       = var.az_list[count.index]

  tags = merge(
    var.common_tags,
    var.private_subnet_tags,
    tomap({
      "Name"="${var.vpc_name}_private_subnet_${count.index + 1}",
      "Tier"="Private",
      "AWSService"="Subnet",
      "NatGateway" = "${var.create_nat_gw}"
})
  )
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = var.single_nat_gw ? aws_route_table.private_rt.*.id[0] : aws_route_table.private_rt.*.id[count.index]
}

# Lambda VPC Endpoint
# resource "aws_vpc_endpoint" "lambda" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.lambda"
#   route_table_ids = local.private_rt_ids

#   # Optional: Security group if needed
#   # security_group_ids = [aws_security_group.some_sg.id]

#   tags = merge(
#     var.common_tags,
#     tomap({
#       "Name" = "${var.vpc_name}_lambda_endpoint",
#       "Tier" = "Private",
#       "AWSService" = "Lambda"
#     })
#   )
# }

# # Secrets Manager VPC Endpoint
# resource "aws_vpc_endpoint" "secrets_manager" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
#   route_table_ids = local.private_rt_ids

#   tags = merge(
#     var.common_tags,
#     tomap({
#       "Name" = "${var.vpc_name}_secrets_manager_endpoint",
#       "Tier" = "Private",
#       "AWSService" = "SecretsManager"
#     })
#   )
# }

# # S3 VPC Endpoint
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
#   route_table_ids = local.private_rt_ids

#   tags = merge(
#     var.common_tags,
#     tomap({
#       "Name" = "${var.vpc_name}_s3_endpoint",
#       "Tier" = "Private",
#       "AWSService" = "S3"
#     })
#   )
# }

# # SNS VPC Endpoint
# resource "aws_vpc_endpoint" "sns" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.sns"
#   route_table_ids = local.private_rt_ids

#   tags = merge(
#     var.common_tags,
#     tomap({
#       "Name" = "${var.vpc_name}_sns_endpoint",
#       "Tier" = "Private",
#       "AWSService" = "SNS"
#     })
#   )
# }

# # SQS VPC Endpoint
# resource "aws_vpc_endpoint" "sqs" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.sqs"
#   route_table_ids = local.private_rt_ids

#   tags = merge(
#     var.common_tags,
#     tomap({
#       "Name" = "${var.vpc_name}_sqs_endpoint",
#       "Tier" = "Private",
#       "AWSService" = "SQS"
#     })
#   )
# }

# # DynamoDB VPC Endpoint
# resource "aws_vpc_endpoint" "dynamodb" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
#   route_table_ids = local.private_rt_ids

#   tags = merge(
#     var.common_tags,
#     tomap({
#       "Name" = "${var.vpc_name}_dynamodb_endpoint",
#       "Tier" = "Private",
#       "AWSService" = "DynamoDB"
#     })
#   )
# }
