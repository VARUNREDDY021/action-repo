output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnet_ids
}

output "private_subnets" {
  value = module.vpc.private_subnet_ids
}

output "ec2_sg_id" {
  value = module.ec2_sg.sg_id
}

output "comm_sg_id" {
  value = module.comm_sg.sg_id
}
