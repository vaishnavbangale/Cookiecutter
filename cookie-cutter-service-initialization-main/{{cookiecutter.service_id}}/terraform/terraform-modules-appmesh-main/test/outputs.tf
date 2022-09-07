output "appmesh_output" {
  value = module.appmesh
}

output "appmesh_service_output" {
  value = module.service
}

output "output_json" {
  value = jsonencode(
    {
      cloud_map_namespace   = module.appmesh.cloud_map_namespace
      cloud_map_id          = module.appmesh.cloud_map_id
      cloud_map_arn         = module.appmesh.cloud_map_arn
      cloud_map_hosted_zone = module.appmesh.cloud_map_hosted_zone
      cloud_map_service = {
        id   = module.service.cloud_map_service_id
        arn  = module.service.cloud_map_service_arn
        name = module.service.cloud_map_service_name
      }
      cloudmap_namespace_description = local.cloudmap_namespace_description
      app_mesh_name                  = "${var.id}-${local.environment}"
      app_mesh_id                    = module.appmesh.app_mesh_id
      app_mesh_arn                   = module.appmesh.app_mesh_arn
      app_mesh_router = {
        arn  = module.service.virtual_router_arn
        name = module.service.virtual_router_name
      }
      app_mesh_virtual_service = {
        id   = module.service.virtual_service_id
        arn  = module.service.virtual_service_arn
        name = module.service.virtual_service_name
      }
      vpc_id            = local.vpc_id
      virtual_node_test = module.service.virtual_nodes["test"]
    }
  )
}