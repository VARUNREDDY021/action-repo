locals {
  any_port     = 0
  https_port   = "443"
  any_protocol = "-1"
  all_ips      = ["0.0.0.0/0"]
}

resource "aws_security_group" "sg" {
  name = "${var.env}-${var.project}-common_sg"
  vpc_id = var.vpc_id
  description = "Terraformed"

 tags = merge(
    var.common_tags
  )
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.sg.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
  description       = "Allow All Traffic Out"
}

resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  security_group_id = aws_security_group.sg.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  self              = true
  description       = "Allow all traffic within self sg"
}