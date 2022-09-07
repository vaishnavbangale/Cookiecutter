# terraform-modules-appmesh: virtual_node #
SubModule that can be used to create app mesh virtual node and virtual service
Wraps around aws_appmesh_virtual_node resource object block to allow inputs as map variables instead of dynamic blocks

# usage #
```hcl
module "virtual_node_frontend" {
  source = "../"

  app_mesh_id = module.appmesh.app_mesh_id
  node_name   = "frontend-app"
  cloud_map_service_discovery = {
    attributes = {
      ECS_TASK_DEFINITION_FAMILY = "frontend-app-sandbox"
    }
    namespace_name = module.appmesh.cloud_map_namespace
    service_name   = "frontend-app"
  }
  listeners = local.app_services["frontend-app"].listeners
  backends = [
    {
      virtual_service_name = "backend-app.example.local"
    }
  ]
  backend_defaults = []
  tags = {
    "Terraform" = "True"
  }
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| tags | Common tags for all resources. | map(string) | n/a | yes |
| app_mesh_id | App mesh ID. | string | n/a | yes |
| node_name | Name of virtual node to create. | string | n/a | yes |
| cloudmap_namespace | Cloud map service namespace information. Used to fill in cloud_map_service_discovery if passed | string | `null` | no |
| cloudmap_service_name | Cloud map service name. Used to fill in cloud_map_service_discovery if passed | string | `null` | no |
| cloud_map_service_discovery | Cloud map service discovery information. | map | `{}` | no |
| dns_service_discovery | DNS service discovery information. | map | `{}` | no |
| backends | List of backend virtual service names. | list | `[]` | no |
| backend_defaults | The defaults for the backends. | list | `[]` | no |
| listeners | Virtual node listener content. | list | `[]` | no |
| service_name | Name of the virtual service to associate the node. If not specified, service will not be created. | string | `null` | no |

## Outputs
| Name | Description |
|------|-------------|
| node_name | Name of the virtual node |
| node_id | ID of the virtual node |
| node_arn | ARN of the virtual node |
| service_id | ID of the virtual service |
| service_arn | ARN of the virtual service |