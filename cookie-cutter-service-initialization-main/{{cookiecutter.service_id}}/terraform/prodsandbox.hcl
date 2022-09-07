# The root terragunt config

remote_state {
  backend = "s3"
  generate = {
    path      = "tg_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.state_bucket}"
    key            = "services/${local.app_name}/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    acl            = "authenticated-read"
    dynamodb_table = "${local.state_dynamodb}"
    role_arn       = "arn:aws:iam::730502903637:role/app-infra-backend-${local.app_name}"
  }
}

generate "variables" {
  path      = "tg_variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
  variable "app_name" {
    type        = string
    description = "Name of the application or project"
  }

  variable "environment" {
    type        = string
    description = "The name of the environment"
  }

  variable "provider_assume_role_name" {
    type        = string
    description = "The name for the aws provider to assume"
  }
  EOF
}

generate "provider" {
  path      = "tg_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "3.75.0"
      }
      datadog = {
        source  = "DataDog/datadog"
        version = "3.4.0"
      }      
    }
  }

  provider "datadog" {
    api_key = data.aws_ssm_parameter.dd_api_key.value
  }

  provider "aws" {
    region  = "us-east-1"
    assume_role {
      role_arn = "arn:aws:iam::${local.account_id}:role/$${var.provider_assume_role_name}"
    }
    default_tags {
      tags = {
        account        = "${local.account}"
        terraform      = true
        terraform-repo = "${local.terraform_repo}"
        region         = "us-east-1"
        hm-project     = var.app_name
        hm-owner       = "${local.owner}"
      }
    }
  }

  provider "aws" {
    alias   = "uswest2"
    region  = "us-west-2"
    assume_role {
      role_arn = "arn:aws:iam::${local.account_id}:role/$${var.provider_assume_role_name}"
    }
    default_tags {
      tags = {
        account        = "${local.account}"
        terraform      = true
        terraform-repo = "${local.terraform_repo}"
        region         = "us-west-2"
        hm-project     = var.app_name
        hm-owner       = "${local.owner}"
      }
    }
  }
  EOF
}

generate "data" {
  path      = "tg_data.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
  data "aws_caller_identity" "current" {}
  data "aws_region" "current" {}
  
  data "aws_ssm_parameter" "dd_api_key" {
    name = "/logging/datadog_token"
  }

  module "lookup_map_ue1" {
    source = "git@github.com:HappyMoneyInc/terraform-modules-get_lookup_map.git?ref=${local.lookup_map_ver}"

    environment = var.environment
  }

  module "lookup_map_uw2" {
    providers = {
      aws = aws.uswest2
    }
    source = "git@github.com:HappyMoneyInc/terraform-modules-get_lookup_map.git?ref=${local.lookup_map_ver}"
    
    environment = var.environment

    get_route53_zone_private_subdomain = false
    get_ecs_cluster_infrafargate       = false
    get_lb_private                     = false
    get_lb_public                      = false
    get_vpc_endpoint_api_gw            = false
    get_star_happymoney_com_arn        = false
    get_virtual_gateway_nlb            = false
    get_virtual_gateway_vpc_link_id    = false
  }

  data "aws_subnet" "priv_us_east_1a_subnet" {
    id = module.lookup_map_ue1.network.priv_subnet_id.a
  }

  data "aws_subnet" "priv_us_east_1b_subnet" {
    id = module.lookup_map_ue1.network.priv_subnet_id.b
  }

  data "aws_subnet" "priv_us_east_1c_subnet" {
    id = module.lookup_map_ue1.network.priv_subnet_id.c
  }
  EOF
}

terraform {
  extra_arguments "common_vars" {
    commands = ["apply"]

    arguments = [
      "-auto-approve"
    ]
  }
}

inputs = {
  app_name = local.project_config.app_name
}

locals {
  project_config = jsondecode(file("${get_parent_terragrunt_dir()}/project.config"))
  terraform_repo = local.project_config.repository
  app_name       = local.project_config.app_name
  owner          = local.project_config.owner
  lookup_map_ver = local.project_config.lookup_map_ver

  account_id     = "475583156226"
  account        = "prodsandbox"
  state_dynamodb = "dyndb-table-app-tf-sharedservices-ue1"
  state_bucket   = "hm-app-tf-state-${local.account}"
}