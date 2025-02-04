locals {
    public_ssh_port = 22
    all_ips      = ["0.0.0.0/0"]
    http_port = 80
    any_port = 0
    any_protocol = "-1"
   
}


resource "aws_security_group" "ec2_sg" {
  name = "${var.env}-${var.shortend_region}-${var.project}-ec2_sg"
  vpc_id = var.vpc_id
  description = "Terraformed"

  tags = merge(
    var.common_tags
  )
}

resource "aws_security_group_rule" "ingress_ssh" {
  description      = "Incoming traffic to ec2"
  type             = "ingress"
  from_port        = local.public_ssh_port
  to_port          = local.public_ssh_port
  protocol         = "TCP"
  cidr_blocks      = local.all_ips

  security_group_id = aws_security_group.ec2_sg.id
}
resource "aws_security_group_rule" "egress_ec2_all" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_sg.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
  description       = "Allow All Traffic Out"
}