# terraform-modules-appmesh: service #
SubModule that can be used to create cloudmap service, app mesh virtual node, virtual route and virtual service
Virtual gateway route can be created when virtual_gateway_route variable is passed

Complex objects for virtual services follow terraform resource schema

# usage #
```hcl
module "service" {
  source = "git@github.com:HappyMoneyInc/terraform-modules-appmesh.git//modules/service?ref=v2.0.7"
  
  cloudmap_namespace = module.appmesh.cloud_map_namespace
  app_mesh_id = module.appmesh.app_mesh_id
  name   = "api"
  health_check_custom_config = {
    failure_threshold = 1
  }
  router_port_mapping = {
    port     = 9080
    protocol = "http"
  }  
  nodes = {
    "blue" = {
        cloud_map_service_discovery = {
            attributes = {
                ECS_TASK_DEFINITION_FAMILY = "app-test-api-blue"
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
                health_check = {
                    healthy_threshold   = 2
                    interval_millis     = 5000
                    protocol            = "tcp"
                    timeout_millis      = 5000
                    unhealthy_threshold = 2
                    port                = 9080
                }
                tls = {
                    mode = "STRICT"
                    certificate = {
                        acm = {
                            certificate_arn = module.appmesh.cloud_map_acm_arn
                        }
                    }
                }
            }              
        ]          
        backends = ["document-service"]
        backend_defaults = [
            {
                client_policy = {
                    tls = {
                        validation = {
                            trust = {
                                acm = {
                                    certificate_authority_arns = [module.appmesh.cloud_map_acmpca_ca_arn]
                                }
                            }
                        }
                    }
                }
            }
        ]
    }   

    routes = [
        {
            path = "/"
            weighted_target = {
                "api" = 100
            }
        }
    ]
  virtual_gateway_route = {
      virtual_gateway_name = aws_appmesh_virtual_gateway.test.name
      match_prefix         = "/"
  }
  tags = {
    "Terraform" = "True"
  }
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cloudmap_namespace | Value of the cloudmap service discovery namespace | string | n/a | yes |
| cloudmap_namespace_type | Value of the cloudmap service discovery namespace type. | string | `DNS_PRIVATE` | yes |
| app_mesh_id | App mesh ID. | string | n/a | yes |
| tags | Common tags for all resources. | map(string) | n/a | yes |
| name | Name of the service. | string | n/a | yes |
| description | Description for the service. | string | `null` | no |
| dns_records | List of DNS records to create for the backend cloudmap service. | list(map) | `[{ttl=60;type="A"},{ttl=60;type="SRV"}]` | no |
| routing_policy | The routing policy that you want to apply to all records that Route 53 creates when you register an instance and specify the service. Valid Values: MULTIVALUE, WEIGHTED. | string | `null` | no |
| health_check_custom_config | Settings for ECS managed health checks. | map | `null` | no |
| health_check_config | Settings for an optional health check. Only for Public DNS namespaces. | map | `null` | no |
| router_port_mapping | Map that defines port and protocol of virtual router listener. | map | `n/a` | yes |
| nodes | Map of virtual node configurations part of the virtual service. Key is included in virtual node name on creation. See nodes properties below. | map | `{}` | no |
| routes | List of service routes with weighted targets objects. | list | `[]` | no |
| virtual_gateway_route | Optional map with virtual_gateway_name and match_prefix for creating a virtual gateway route to the service. | map(string) | `null` | no |
| http_service_route_retry_enabled | Optional boolean. If true, enables service route retry for http route | bool | `true` | no |

#### Nodes Properties
| Name | Description |
|------|-------------|
| cloud_map_service_discovery | Optional. Map object with string map property `attributes` with values used to filter instances by any custom attribute specified when registering matched instances. |
| dns_service_discovery | Optional. Map object with string property `hostname` where value is the DNS hostname for virtual node. |
| listeners | Optional. Virtual node listener content with attributes `port_mapping`, `health_check`, `connection_pool`, `timeout`  |
| backends | Optional. List made of string service names without the cloudmap namespace included or maps that include `virtual_service_name` and optional `client_policy` map or a combination of both. String is the simple input where cloudmap namespace is automatically appended to it. Use a map input if required to define non-cloudmap namespace backends or individual client policies.  |
| backend_defaults | Optional. List of maps to define the defaults for the backends. |

## Outputs
| Name | Description |
|------|-------------|
| cloud_map_service_id | Provisioned cloud map service id |
| cloud_map_service_arn | Provisioned cloud map service arn |
| cloud_map_service_name | Provisioned cloud map service name |
| virtual_service_id | ID of the virtual service |
| virtual_service_arn | ARN of the virtual service |
| virtual_service_name | Name of the virtual service |
| virtual_router_id | ID of the virtual router |
| virtual_router_arn | ARN of the virtual router |
| virtual_router_name | Name of the virtual router |
| virtual_nodes | Map of virtual nodes provisioned |
| virtual_routes | List of virtual routes provisioned for service |
| virtual_gateway_route | Virtual gateway route provisioned |