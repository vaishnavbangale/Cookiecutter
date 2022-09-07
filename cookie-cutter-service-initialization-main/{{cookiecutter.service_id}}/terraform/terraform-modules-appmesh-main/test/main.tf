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
  vpc_id      = "vpc-03207458f7f9b482e"
  environment = "sandbox"
  tags = {
    "account"        = "sandbox"
    "terraform"      = "true"
    "terraform-repo" = "terraform-modules-appmesh"
    "env"            = "sandbox"
    "hm-service"     = "test"
    "hm-project"     = "devops"
    "public-facing"  = "false"
    "region"         = "us-east-1"
  }
  cloudmap_namespace             = "${var.id}.local"
  cloudmap_namespace_description = "terraform-modules-appmesh module end-to-end testing"
  service_name                   = "api"
}

# App mesh and service discovery
module "appmesh" {
  source = "../"

  tags = merge(
    local.tags,
    {
      terraform-module = "module.appmesh"
    }
  )

  vpc_id                         = local.vpc_id
  cloudmap_namespace             = local.cloudmap_namespace
  cloudmap_namespace_description = local.cloudmap_namespace_description
  mesh_name                      = "${var.id}-${local.environment}"
  mesh_egress_filter             = "ALLOW_ALL"
}

resource "aws_appmesh_virtual_gateway" "test" {
  name      = "${var.id}-${local.environment}-gw"
  mesh_name = module.appmesh.app_mesh_id

  spec {
    listener {
      port_mapping {
        port     = 9080
        protocol = "http"
      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name               = "${var.id}-${local.environment}-gw"
      terraform-resource = "aws_appmesh_virtual_gateway.test"
    }
  )
}

module "service" {
  source = "../modules/service"

  cloudmap_namespace = module.appmesh.cloud_map_namespace
  app_mesh_id        = module.appmesh.app_mesh_id
  name               = local.service_name
  health_check_custom_config = {
    failure_threshold = 1
  }
  router_port_mapping = {
    port     = 9080
    protocol = "http"
  }
  nodes = {
    "test" = {
      cloud_map_service_discovery = {
        attributes = {
          ECS_TASK_DEFINITION_FAMILY = "app-test-api"
        }
      }
      listeners = [
        {
          port_mapping = [
            {
              port     = 9080
              protocol = "http"
            }
          ]
        }
      ]
      backends = ["backend-service"]
    }
  }

  routes = [
    {
      path = "/"
      weighted_target = {
        "test" = 100
      }
      timeout = {
        per_request = {
          unit  = "s"
          value = 30
        }
      }
    }
  ]
  virtual_gateway_route = {
    virtual_gateway_name = aws_appmesh_virtual_gateway.test.name
    match_prefix         = "/"
  }

  tags = merge(
    local.tags,
    {
      terraform-module = "module.service"
    }
  )

  depends_on = [module.appmesh]
}