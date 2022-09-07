module "nlb_private_subnet_cidr" {
  source                   = "./modules/elb_nic_private_ips"
  for_each                 = local.nlb_targets
  subnet_ids               = var.load_balancer_subnet_ids == null ? var.subnet_ids : var.load_balancer_subnet_ids
  load_balancer_arn_suffix = each.value["load_balancer_arn_suffix"]
}

data "aws_ami" "application_service" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

data "aws_ssm_parameter" "dd_api_key" {
  name = "/logging/datadog_token"
}

data "aws_secretsmanager_secret" "dockerhub" {
  name = "dockerhub_credentials"
}
