terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.57.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "id" {
  type = string
}

locals {
  vpc_id           = "vpc-03207458f7f9b482e"
  vpc_cidr         = ["10.208.0.0/16"]
  route53_record_1 = "${local.app_name_1}.sandbox.aws-ue1.happymoney.com"
  route53_record_2 = "${local.app_name_2}.sandbox.aws-ue1.happymoney.com"
  ecs_network_access_cidrs = [
    "10.208.0.0/16",
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
  app_name_1        = "ecs1-${var.id}"
  app_name_2        = "ecs2-${var.id}"
  cluster_id        = "arn:aws:ecs:us-east-1:512436868621:cluster/ecs-cluster-infraFargate-sandbox-ue1"
  cluster_name      = "ecs-cluster-infraFargate-sandbox-ue1"
  account_id        = "512436868621"
  test_ecr_repo_arn = "arn:aws:ecr:us-east-1:840364872350:repository/aws-appmesh-envoy"
  test_ecr_repo_url = "840364872350.dkr.ecr.us-east-1.amazonaws.com/aws-appmesh-envoy:v1.17.2.0-prod"
  region_abbrv      = "ue1"

  auto_scaling_thresholds = {
    app_1 = {
      ecs_alarms_cpu_low_threshold     = 20
      ecs_alarms_cpu_high_threshold    = 70
      ecs_alarms_memory_low_threshold  = 20
      ecs_alarms_memory_high_threshold = 70
    }
    app_2 = {
      ecs_alarms_cpu_low_threshold     = 40
      ecs_alarms_cpu_high_threshold    = 60
      ecs_alarms_memory_low_threshold  = 40
      ecs_alarms_memory_high_threshold = 60
    }
  }
}

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "hm-tf-state"
    key    = "core/sandbox/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "terratest_infra" {
  backend = "s3"
  config = {
    bucket = "hm-tf-state"
    key    = "sandbox/terratest_infra/ecs_service.tfstate"
    region = "us-east-1"
  }
}

resource "random_integer" "nlb_port" {
  min = 80
  max = 65535
}

resource "random_id" "alb_http_header" {
  byte_length = 24
}

#---------------------------------------------------------------------------------
# Test using the module

module "test_ecs_service" {
  source = "../"

  task_start_commands    = ["sleep 1000"]
  environment            = local.environment
  application_name       = local.app_name_1
  ecs_cluster_id         = local.cluster_id
  network_access_cidrs   = local.ecs_network_access_cidrs
  enable_execute_command = true

  subnet_ids = [
    data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id,
  ]
  health_check_grace_period_seconds = 10
  targets = {
    one = {
      port                            = 80
      service_paths                   = ["/*"]
      host_headers                    = [local.route53_record_1]
      lb_type                         = "alb"
      listener_arn                    = data.terraform_remote_state.terratest_infra.outputs.alb_listener_arn
      load_balancer_arn               = data.terraform_remote_state.terratest_infra.outputs.alb_load_balancer_arn
      load_balancer_security_group_id = data.terraform_remote_state.terratest_infra.outputs.alb_load_balancer_security_group_id
      health_check = {
        enabled = true
        path    = "/"
        port    = 87
      }
    },
    two = {
      port                            = 88
      service_paths                   = ["/test/*"]
      host_headers                    = [local.route53_record_1]
      lb_type                         = "alb"
      listener_arn                    = data.terraform_remote_state.terratest_infra.outputs.alb_listener_arn
      load_balancer_arn               = data.terraform_remote_state.terratest_infra.outputs.alb_load_balancer_arn
      load_balancer_security_group_id = data.terraform_remote_state.terratest_infra.outputs.alb_load_balancer_security_group_id
      health_check = {
        path = "/"
        port = 88
      }
      http_headers = {
        header_name = "X-Custom-Header"
        values      = [random_id.alb_http_header.id]
      }
    },
    three = {
      port                            = 98
      service_paths                   = ["/temp/*"]
      host_headers                    = [local.route53_record_1]
      lb_type                         = "alb"
      listener_arn                    = data.terraform_remote_state.terratest_infra.outputs.alb_listener_arn
      load_balancer_arn               = data.terraform_remote_state.terratest_infra.outputs.alb_load_balancer_arn
      load_balancer_security_group_id = data.terraform_remote_state.terratest_infra.outputs.alb_load_balancer_security_group_id
    }
  }
  vpc_cidr      = local.vpc_cidr
  vpc_id        = local.vpc_id
  desired_count = 1
  tags = merge(
    local.tags,
    {
      terraform-module = "module.test_ecs_service"
    }
  )
  region       = "us-east-1"
  launch_type  = "FARGATE"
  ecr_repo_arn = local.test_ecr_repo_arn
  ecr_repo_url = local.test_ecr_repo_url
  account_id   = local.account_id
  dd_tags = {
    "project" = "ecs-service-terratest-alb",
    "env"     = "sandbox"
  }
  container_cpu                    = 512
  container_memory                 = 1024
  container_volumes                = []
  ecs_alarms_cpu_low_threshold     = local.auto_scaling_thresholds.app_1.ecs_alarms_cpu_low_threshold
  ecs_alarms_cpu_high_threshold    = local.auto_scaling_thresholds.app_1.ecs_alarms_cpu_high_threshold
  ecs_alarms_memory_low_threshold  = local.auto_scaling_thresholds.app_1.ecs_alarms_memory_low_threshold
  ecs_alarms_memory_high_threshold = local.auto_scaling_thresholds.app_1.ecs_alarms_memory_high_threshold
  max_capacity                     = 3
  min_capacity                     = 1
  ecs_cluster_name                 = local.cluster_name
  environmentfile_bucket_paths     = []
  environmentfile_kms_arn          = ""
  ephemeral_storage                = 21

  capacity_provider_strategies = [{
    capacity_provider = "FARGATE"
    weight            = 1
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 9
      base              = 1 # or like: local.app_service.ecs_settings["min_capacity"]
  }]

  ecs_task_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "ecr:GetAuthorizationToken",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
  secret_variables = [
    {
      name      = "TEST_VAR",
      valueFrom = aws_ssm_parameter.param.arn
    }
  ]
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }
  security_group_ids = [aws_security_group.sg.id]
}

module "test_ecs_service_nlb" {
  source = "../"

  task_start_commands  = ["sleep 1000"]
  environment          = local.environment
  application_name     = local.app_name_2
  ecs_cluster_id       = local.cluster_id
  network_access_cidrs = local.ecs_network_access_cidrs
  subnet_ids = [
    data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id,
  ]
  targets = {
    one = {
      port                     = 80
      service_paths            = ["/*"]
      host_headers             = [local.route53_record_2]
      lb_type                  = "nlb"
      load_balancer_arn        = data.terraform_remote_state.terratest_infra.outputs.nlb_load_balancer_arn
      load_balancer_arn_suffix = data.terraform_remote_state.terratest_infra.outputs.nlb_load_balancer_arn_suffix
      lb_certificate_arn       = data.terraform_remote_state.core.outputs.star_awsue1_happymoney_com_arn
      lb_port                  = random_integer.nlb_port.result
      protocol                 = "TLS"
      health_check = {
        protocol = "TCP"
      }
    }
  }
  container_service_ports = [80]
  vpc_cidr                = local.vpc_cidr
  vpc_id                  = local.vpc_id

  desired_count = 1
  tags = merge(
    local.tags,
    {
      terraform-module = "module.test_ecs_service_nlb"
    }
  )
  region       = "us-east-1"
  launch_type  = "FARGATE"
  ecr_repo_arn = local.test_ecr_repo_arn
  ecr_repo_url = local.test_ecr_repo_url

  account_id = local.account_id
  dd_tags = {
    "project" = "ecs-service-terratest-nlb",
    "env"     = "sandbox"
  }
  container_cpu                    = 512
  container_memory                 = 1024
  container_volumes                = []
  ecs_alarms_cpu_low_threshold     = local.auto_scaling_thresholds.app_2.ecs_alarms_cpu_low_threshold
  ecs_alarms_cpu_high_threshold    = local.auto_scaling_thresholds.app_2.ecs_alarms_cpu_high_threshold
  ecs_alarms_memory_low_threshold  = local.auto_scaling_thresholds.app_2.ecs_alarms_memory_low_threshold
  ecs_alarms_memory_high_threshold = local.auto_scaling_thresholds.app_2.ecs_alarms_memory_high_threshold
  max_capacity                     = 3
  min_capacity                     = 1
  ecs_cluster_name                 = local.cluster_name
  environmentfile_bucket_paths     = []
  environmentfile_kms_arn          = ""
  propagate_tags                   = "SERVICE"
}
