# SubModule that can be used to create app mesh virtual node and virtual service
# Wraps around virtual node resource object block to allow inputs as map variables however it overuses dynamic blocks.

variable "app_mesh_id" {
  type        = string
  description = "App mesh ID."
}

variable "node_name" {
  type        = string
  description = "Name of virtual node to create."
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources."
}

variable "cloud_map_service_discovery" {
  description = "Cloud map service discovery information."
  default     = {}
}

variable "cloudmap_namespace" {
  type        = string
  description = "Cloud map service namespace information. Used to fill in cloud_map_service_discovery if passed"
  default     = null
}

variable "cloudmap_service_name" {
  type        = string
  description = "Cloud map service name. Used to fill in cloud_map_service_discovery if passed"
  default     = null
}

variable "dns_service_discovery" {
  description = "DNS service discovery information."
  default     = {}
}

variable "backends" {
  description = "List of backend virtual service names."
  default     = []
}

variable "backend_defaults" {
  description = "The defaults for the backends"
  default     = []
}

variable "listeners" {
  description = "Virtual node listener content."
  default     = []
}

variable "service_name" {
  type        = string
  description = "Name of the virtual service to associate the node. If not specified, service will not be created."
  default     = null
}

#---------------------------------------------------------------

resource "aws_appmesh_virtual_node" "node" {
  name      = var.node_name
  mesh_name = var.app_mesh_id

  spec {
    # The backends to which the virtual node is expected to send outbound traffic
    dynamic "backend" {
      for_each = var.backends
      content {
        virtual_service {
          virtual_service_name = backend.value["virtual_service_name"]
          client_policy {
            dynamic "tls" {
              for_each = lookup(lookup(backend.value, "client_policy", {}), "tls", null) == null ? [] : [backend.value["client_policy"]["tls"]]
              content {
                enforce = lookup(tls.value, "enforce", null)
                ports   = lookup(tls.value, "ports", null)
                dynamic "validation" {
                  for_each = lookup(tls.value, "validation", null) == null ? [] : [tls.value["validation"]]
                  content {
                    trust {
                      dynamic "acm" {
                        for_each = lookup(validation.value, "certificate_authority_arns", null) == null ? [] : [validation.value["certificate_authority_arns"]]
                        content {
                          certificate_authority_arns = acm.value
                        }
                      }
                      dynamic "file" {
                        for_each = lookup(validation.value, "certificate_chain", null) == null ? [] : [validation.value["certificate_chain"]]
                        content {
                          certificate_chain = file.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } #End of backend content block
    }   #End of backend dynamic block

    dynamic "backend_defaults" {
      for_each = var.backend_defaults
      content {
        client_policy {
          tls {
            validation {
              trust {
                acm {
                  certificate_authority_arns = backend_defaults.value.client_policy.tls.validation.trust.acm.certificate_authority_arns
                }
              }
            }
          }
        }
      }
    }

    # The listeners from which the virtual node is expected to receive inbound traffic
    dynamic "listener" {
      for_each = var.listeners
      content {
        dynamic "port_mapping" {
          for_each = listener.value["port_mapping"]
          content {
            port     = port_mapping.value["port"]
            protocol = port_mapping.value["protocol"]
          }
        } # End of port_mapping dynamic block

        dynamic "connection_pool" {
          for_each = lookup(listener.value, "connection_pool", {}) == {} ? [] : [listener.value["connection_pool"]]
          content {
            dynamic "grpc" {
              for_each = lookup(connection_pool.value, "grpc", {}) == {} ? [] : [connection_pool.value["grpc"]]
              content {
                max_requests = grpc.value["max_requests"]
              }
            }
            dynamic "http" {
              for_each = lookup(connection_pool.value, "http", {}) == {} ? [] : [connection_pool.value["http"]]
              content {
                max_connections      = http.value["max_connections"]
                max_pending_requests = lookup(http.value, "max_pending_requests", null)
              }
            }
            dynamic "http2" {
              for_each = lookup(connection_pool.value, "ghttp2rpc", {}) == {} ? [] : [connection_pool.value["http2"]]
              content {
                max_requests = http2.value["max_requests"]
              }
            }
            dynamic "tcp" {
              for_each = lookup(connection_pool.value, "tcp", {}) == {} ? [] : [connection_pool.value["tcp"]]
              content {
                max_connections = tcp.value["max_connections"]
              }
            }
          } # End of connection_pool content block
        }   # End of connection_pool dynamic block

        dynamic "health_check" {
          for_each = lookup(listener.value, "health_check", {}) == {} ? [] : [listener.value["health_check"]]
          content {
            healthy_threshold   = health_check.value["healthy_threshold"]
            interval_millis     = health_check.value["interval_millis"]
            protocol            = health_check.value["protocol"]
            timeout_millis      = health_check.value["timeout_millis"]
            unhealthy_threshold = health_check.value["unhealthy_threshold"]
            path                = lookup(health_check.value, "path", null)
            port                = lookup(health_check.value, "port", null)
          }
        } # End of healthcheck dynamic block

        dynamic "tls" {
          for_each = lookup(listener.value, "tls", null) == null ? [] : [listener.value["tls"]]
          content {
            mode = tls.value["mode"]
            certificate {
              dynamic "acm" {
                for_each = lookup(lookup(tls.value, "certificate", {}), "acm", null) == null ? [] : [tls.value["certificate"]["acm"]]
                content {
                  certificate_arn = acm.value["certificate_arn"]
                }
              }
              dynamic "file" {
                for_each = lookup(lookup(tls.value, "certificate", {}), "file", null) == null ? [] : [tls.value["certificate"]["file"]]
                content {
                  certificate_chain = file.value["certificate_chain"]
                  private_key       = file.value["private_key"]
                }
              }
            }
          }
        } # End of tls dynamic block

        dynamic "timeout" {
          for_each = lookup(listener.value, "timeout", {}) == {} ? [] : [listener.value["timeout"]]
          content {
            dynamic "grpc" {
              for_each = lookup(timeout.value, "grpc", {}) == {} ? [] : [timeout.value["grpc"]]
              content {
                dynamic "idle" {
                  for_each = lookup(grpc.value, "idle", null) == null ? [] : [grpc.value["idle"]]
                  content {
                    unit  = idle.value["unit"]
                    value = idle.value["value"]
                  }
                }
                dynamic "per_request" {
                  for_each = lookup(grpc.value, "per_request", null) == null ? [] : [grpc.value["per_request"]]
                  content {
                    unit  = per_request.value["unit"]
                    value = per_request.value["value"]
                  }
                }
              }
            }
            dynamic "http" {
              for_each = lookup(timeout.value, "http", {}) == {} ? [] : [timeout.value["http"]]
              content {
                dynamic "idle" {
                  for_each = lookup(http.value, "idle", null) == null ? [] : [http.value["idle"]]
                  content {
                    unit  = idle.value["unit"]
                    value = idle.value["value"]
                  }
                }
                dynamic "per_request" {
                  for_each = lookup(http.value, "per_request", null) == null ? [] : [http.value["per_request"]]
                  content {
                    unit  = per_request.value["unit"]
                    value = per_request.value["value"]
                  }
                }
              }
            }
            dynamic "http2" {
              for_each = lookup(timeout.value, "http2", {}) == {} ? [] : [timeout.value["http2"]]
              content {
                dynamic "idle" {
                  for_each = lookup(http2.value, "idle", null) == null ? [] : [http2.value["idle"]]
                  content {
                    unit  = idle.value["unit"]
                    value = idle.value["value"]
                  }
                }
                dynamic "per_request" {
                  for_each = lookup(http2.value, "per_request", null) == null ? [] : [http2.value["per_request"]]
                  content {
                    unit  = per_request.value["unit"]
                    value = per_request.value["value"]
                  }
                }
              }
            }
            dynamic "tcp" {
              for_each = lookup(timeout.value, "tcp", {}) == {} ? [] : [timeout.value["tcp"]]
              content {
                dynamic "idle" {
                  for_each = lookup(tcp.value, "idle", null) == null ? [] : [tcp.value["idle"]]
                  content {
                    unit  = idle.value["unit"]
                    value = idle.value["value"]
                  }
                }
              }
            }
          } # End of timeout content block
        }   # End of timeout dynamic block
      }     # End of listener content block
    }       # End of listener dynamic block


    service_discovery {
      dynamic "aws_cloud_map" {
        for_each = var.cloud_map_service_discovery == {} ? [] : [var.cloud_map_service_discovery]
        content {
          attributes     = lookup(aws_cloud_map.value, "attributes", null)
          namespace_name = var.cloudmap_namespace != null ? var.cloudmap_namespace : aws_cloud_map.value["namespace_name"]
          service_name   = var.cloudmap_service_name != null ? var.cloudmap_service_name : aws_cloud_map.value["service_name"]
        }
      }

      dynamic "dns" {
        for_each = var.dns_service_discovery == {} ? [] : [var.dns_service_discovery]
        content {
          hostname = dns.value["hostname"]
        }
      }
    } # End of service_discovery block
  }   # End of spec block

  tags = merge(
    var.tags,
    {
      Name               = var.node_name
      terraform-resource = "aws_appmesh_virtual_node.node"
    }
  )
}

resource "aws_appmesh_virtual_service" "service" {
  count     = var.service_name == null ? 0 : 1
  name      = var.service_name
  mesh_name = var.app_mesh_id

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.node.name
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = var.service_name
      terraform-resource = "aws_appmesh_virtual_service.service"
    }
  )
}

#---------------------------------------------------------------
# Outputs

output "node_name" {
  description = "Name of the virtual node"
  value       = aws_appmesh_virtual_node.node.name
}

output "node_id" {
  description = "ID of the virtual node"
  value       = aws_appmesh_virtual_node.node.id
}

output "node_arn" {
  description = "ARN of the virtual node"
  value       = aws_appmesh_virtual_node.node.arn
}

output "service_id" {
  description = "ID of the virtual service"
  value       = var.service_name == null ? null : aws_appmesh_virtual_service.service[0].id
}

output "service_arn" {
  description = "ARN of the virtual service"
  value       = var.service_name == null ? null : aws_appmesh_virtual_service.service[0].name
}