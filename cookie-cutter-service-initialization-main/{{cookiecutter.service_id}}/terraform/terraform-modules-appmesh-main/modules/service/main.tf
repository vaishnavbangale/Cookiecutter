data "aws_service_discovery_dns_namespace" "cloudmap" {
  name = var.cloudmap_namespace
  type = var.cloudmap_namespace_type
}

resource "aws_service_discovery_service" "cloudmap_service" {
  name         = var.name
  description  = var.description
  namespace_id = data.aws_service_discovery_dns_namespace.cloudmap.id

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.cloudmap.id

    dynamic "dns_records" {
      for_each = [for this_record in var.dns_records : {
        ttl  = this_record.ttl
        type = this_record.type
      }]
      content {
        ttl  = dns_records.value.ttl
        type = dns_records.value.type
      }
    }

    routing_policy = var.routing_policy
  }

  dynamic "health_check_custom_config" {
    for_each = var.health_check_custom_config == null ? [] : [var.health_check_custom_config]
    content {
      failure_threshold = lookup(health_check_custom_config.value, "failure_threshold", null)
    }
  }

  dynamic "health_check_config" {
    for_each = var.health_check_config == null ? [] : [var.health_check_config]
    content {
      failure_threshold = lookup(health_check_config.value, "failure_threshold", null)
      resource_path     = lookup(health_check_config.value, "resource_path", null)
      type              = lookup(health_check_config.value, "type", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = var.name
      terraform-resource = "aws_service_discovery_service.cloudmap_service"
    }
  )
}

resource "aws_appmesh_virtual_router" "router" {
  name      = "${var.name}-router"
  mesh_name = var.app_mesh_id

  spec {
    listener {
      port_mapping {
        port     = var.router_port_mapping.port
        protocol = var.router_port_mapping.protocol
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = "${var.name}-router"
      terraform-resource = "aws_appmesh_virtual_router.router"
    }
  )
}

resource "aws_appmesh_virtual_service" "service" {
  name      = "${var.name}.${var.cloudmap_namespace}"
  mesh_name = var.app_mesh_id

  spec {
    provider {
      virtual_router {
        virtual_router_name = aws_appmesh_virtual_router.router.name
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = "${var.name}.${var.cloudmap_namespace}"
      terraform-resource = "aws_appmesh_virtual_service.service"
    }
  )
}


module "virtual_nodes" {
  source   = "./virtual_node"
  for_each = var.nodes

  app_mesh_id                 = var.app_mesh_id
  node_name                   = "${var.name}-${each.key}"
  cloudmap_namespace          = lookup(each.value, "cloud_map_service_discovery", {}) != {} ? var.cloudmap_namespace : null
  cloudmap_service_name       = lookup(each.value, "cloud_map_service_discovery", {}) != {} ? var.name : null
  cloud_map_service_discovery = lookup(each.value, "cloud_map_service_discovery", {})
  dns_service_discovery       = lookup(each.value, "dns_service_discovery", {})
  listeners                   = lookup(each.value, "listeners", [])
  backends = [
    for backend in lookup(each.value, "backends", []) : {
      virtual_service_name = try(backend.virtual_service_name, "${backend}.${var.cloudmap_namespace}")
      client_policy        = try(backend.client_policy, {})
    }
  ]
  backend_defaults = lookup(each.value, "backend_defaults", [])

  tags = merge(
    var.tags,
    {
      terraform-module = lookup(var.tags, "terraform-module", null) != null ? "${var.tags["terraform-module"]}.module.virtual_nodes" : "module.virtual_nodes"
    }
  )
}

locals {
  routes = { for route in var.routes : route["path"] => route }
}

resource "aws_appmesh_route" "service-route" {
  for_each            = local.routes
  name                = "${var.name}-route_${replace(each.key, "/[\\/]/", "-")}"
  mesh_name           = var.app_mesh_id
  virtual_router_name = aws_appmesh_virtual_router.router.name

  spec {
    http_route {
      match {
        prefix = each.value.path
      }

      action {
        dynamic "weighted_target" {
          for_each = each.value["weighted_target"]
          content {
            virtual_node = module.virtual_nodes[weighted_target.key].node_name
            weight       = weighted_target.value
          }
        }
      }

      dynamic "retry_policy" {
        for_each = var.http_service_route_retry_enabled ? [1] : []
        content {
          http_retry_events = [
            "server-error",
          ]
          max_retries = lookup(each.value, "retry_policy", {}) != {} ? lookup(each.value["retry_policy"], "max_retries", 1) : 1

          per_retry_timeout {
            unit = lookup(each.value, "retry_policy", {}) != {} ? (
              lookup(each.value["retry_policy"], "per_retry_timeout", {}) != {} ? lookup(each.value["retry_policy"]["per_retry_timeout"], "unit", "s") : "s"
            ) : "s"
            value = lookup(each.value, "retry_policy", {}) != {} ? (
              lookup(each.value["retry_policy"], "per_retry_timeout", {}) != {} ? lookup(each.value["retry_policy"]["per_retry_timeout"], "value", 15) : 15
            ) : 15
          }
        }
      }

      dynamic "timeout" {
        for_each = lookup(each.value, "timeout", null) == null ? [] : [each.value["timeout"]]
        content {
          dynamic "idle" {
            for_each = lookup(timeout.value, "idle", null) == null ? [] : [timeout.value["idle"]]
            content {
              unit  = lookup(idle.value, "unit", null)
              value = lookup(idle.value, "value", null)
            }
          }
          dynamic "per_request" {
            for_each = lookup(timeout.value, "per_request", null) == null ? [] : [timeout.value["per_request"]]
            content {
              unit  = lookup(per_request.value, "unit", null)
              value = lookup(per_request.value, "value", null)
            }
          }
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = "${var.name}-route_${replace(each.key, "/[\\/]/", "-")}"
      terraform-resource = "aws_appmesh_route.service-route"
    }
  )
}

# Associate to Virtual gateway
resource "aws_appmesh_gateway_route" "gw_route" {
  count                = var.virtual_gateway_route == null ? 0 : 1
  name                 = "${var.name}-gw-route"
  mesh_name            = var.app_mesh_id
  virtual_gateway_name = var.virtual_gateway_route["virtual_gateway_name"]

  spec {
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.service.name
          }
        }
      }

      match {
        prefix = var.virtual_gateway_route["match_prefix"]
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = "${var.name}-gw-route"
      terraform-resource = "aws_appmesh_gateway_route.gw_route"
    }
  )
}