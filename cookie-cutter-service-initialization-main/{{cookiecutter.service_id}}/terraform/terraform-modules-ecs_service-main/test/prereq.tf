# Sandbox
resource "aws_ssm_parameter" "param" {
  name  = "/${var.id}/test_param_secret"
  type  = "SecureString"
  value = "test"

  tags = merge(
    local.tags,
    {
      Name               = "/${var.id}/test_param_secret"
      terraform-resource = "aws_ssm_parameter.param"
    }
  )
}

resource "aws_security_group" "sg" {
  name        = "ec-sg-${var.id}"
  description = "ECS Service module test"
  vpc_id      = local.vpc_id

  tags = merge(
    local.tags,
    {
      Name               = "ec-sg-${var.id}"
      terraform-resource = "aws_security_group.sg"
    }
  )
}

resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
