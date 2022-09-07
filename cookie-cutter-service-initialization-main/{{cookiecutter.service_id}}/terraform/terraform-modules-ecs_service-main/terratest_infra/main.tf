# Backend prereq infra resources used by terratest.
# Note: Currently both main and feature branches share this infrastructure so this template 
#       should not be updated without coordination.
provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.57.0"
    }
  }
  backend "s3" {
    bucket         = "hm-tf-state"
    key            = "sandbox/terratest_infra/ecs_service.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dyndb-table-tf-sandboxAccount-ue1"
    encrypt        = true
    acl            = "authenticated-read"
  }
}

locals {
  vpc_id          = "vpc-03207458f7f9b482e"
  route53_zone_id = "Z0740639EZRGHG4IBZKI"
  ecs_network_access_cidrs = [
    data.aws_subnet.priv_us_east_1a_subnet.cidr_block,
    data.aws_subnet.priv_us_east_1b_subnet.cidr_block,
    data.aws_subnet.priv_us_east_1c_subnet.cidr_block,
    "172.25.0.0/22",
    "172.25.4.0/22",
    # cisco anyconnect vpns (vpn v1)
    "10.230.1.0/24",
    "10.230.2.0/24",
    "10.230.3.0/24",
    "10.230.4.0/24",
    "10.230.5.0/24",
    "172.25.8.0/22",
    "10.230.6.0/24",
    # openvpn zt cloud connectors (vpn v2)
    "172.25.20.0/22",
    "10.230.20.0/24",
    "172.25.44.0/22",
    "10.230.44.0/24",
    "172.25.28.0/22",
    "10.230.28.0/24",
    "172.25.32.0/22",
    "10.230.32.0/24",
    "172.25.36.0/22",
    "10.230.36.0/24",
    "172.25.40.0/22",
    "10.230.40.0/24"
  ]
  environment = "sandbox"
  tags = {
    "account"        = "sandbox"
    "terraform"      = "true"
    "terraform-repo" = "terraform-modules-ecs_service"
    "env"            = "sandbox"
    "hm-service"     = "test"
    "hm-project"     = "devops"
    "public-facing"  = "false"
    "region"         = "us-east-1"
  }
  alb_app_name = "terratest"
  nlb_app_name = "terratest"
  region_abbrv = "ue1"
}

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "hm-tf-state"
    key    = "core/sandbox/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_subnet" "priv_us_east_1a_subnet" {
  id = data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id
}

data "aws_subnet" "priv_us_east_1b_subnet" {
  id = data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id
}

data "aws_subnet" "priv_us_east_1c_subnet" {
  id = data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id
}

module "alb" {
  source = "git@github.com:HappyMoneyInc/terraform-modules-load_balancer.git?ref=v2.0.8"

  application_name   = local.alb_app_name
  default_redirect   = "happymoney.com"
  vpc_id             = local.vpc_id
  route53_zone_id    = local.route53_zone_id
  environment        = local.environment
  region_abbrv       = local.region_abbrv
  lb_certificate_arn = data.terraform_remote_state.core.outputs.star_awsue1_happymoney_com_arn
  subnets = [
    data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id,
  ]

  alb_egress_rules = {
    "egress_all" = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  alb_ingress_rules = {
    "https" = {
      description = "HTTPS External Access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.ecs_network_access_cidrs
    },
    "http" = {
      description = "HTTP External Access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = local.ecs_network_access_cidrs
    }
  }

  tags = merge(
    local.tags,
    {
      terraform-module = "module.alb"
    }
  )
}

module "nlb" {
  source = "git@github.com:HappyMoneyInc/terraform-modules-load_balancer.git?ref=v2.0.8"

  load_balancer_type = "network"
  application_name   = local.nlb_app_name
  route53_zone_id    = local.route53_zone_id
  subnets = [
    data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id,
  ]

  environment  = local.environment
  region_abbrv = local.region_abbrv

  tags = merge(
    local.tags,
    {
      terraform-module = "module.nlb"
    }
  )
}

output "alb_listener_arn" {
  value = module.alb.listener_arn
}

output "alb_load_balancer_arn" {
  value = module.alb.load_balancer_arn
}

output "alb_load_balancer_security_group_id" {
  value = module.alb.load_balancer_security_group_id
}

output "nlb_load_balancer_arn" {
  value = module.nlb.load_balancer_arn
}

output "nlb_load_balancer_arn_suffix" {
  value = module.nlb.load_balancer_arn_suffix
}