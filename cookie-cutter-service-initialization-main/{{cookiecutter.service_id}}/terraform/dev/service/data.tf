# Data
data "aws_service_discovery_dns_namespace" "mesh" {
  name = "${var.environment}.mesh.local"
  type = "DNS_PRIVATE"
}

data "aws_acm_certificate" "mesh" {
  domain   = "*.${var.environment}.mesh.local"
  statuses = ["ISSUED"]
}

data "aws_appmesh_mesh" "mesh" {
  name = "${var.environment}-mesh"
}

data "aws_ssm_parameter" "mesh_cloud_map_acmpca_ca_arn" {
  name = "/infra/${var.environment}/appmesh/cloud_map_acmpca_ca_arn"
}

data "aws_secretsmanager_secret" "dockerhub" {
  name = "dockerhub_credentials"
}

locals {
  tls = {
    mode = "STRICT"
    certificate = {
      acm = {
        certificate_arn = data.aws_acm_certificate.mesh.arn
      }
    }
  }
  backend_defaults = [
    {
      client_policy = {
        tls = {
          validation = {
            trust = {
              acm = {
                certificate_authority_arns = [nonsensitive(data.aws_ssm_parameter.mesh_cloud_map_acmpca_ca_arn.value)]
              }
            }
          }
        }
      }
    }
  ]
}