output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "vpc_name" {
    value = var.vpc_name
}
# Output public subnets
output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
  description = "The IDs of the public subnets"
}

# Output private subnets
output "private_subnet_ids" {
  value = aws_subnet.private_subnet[*].id
  description = "The IDs of the private subnets"
}