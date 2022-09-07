output "environment" {
  value = var.environment
}

output "account" {
  value = module.lookup_map_ue1.account_name
}

output "service" {
  value = {
    ecs = {
      cluster = split("/", module.lookup_map_ue1.ecs_cluster.infrafargate)[1]
      service = {
        green = {
          name                 = module.ecs_green.ecs_service_name
          s3_environment_files = module.ecs_green.environment_files
          task_role            = module.ecs_green.task_role_arn
          exec_role            = module.ecs_green.execution_role_arn
        }
      }
    }
    appmesh = {
      cloudmap_namespace    = data.aws_service_discovery_dns_namespace.mesh.name
      cloudmap_service_name = module.mesh_service.cloud_map_service_name
      mesh                  = data.aws_appmesh_mesh.mesh.id
      virtual_service_name  = module.mesh_service.virtual_service_name
      virtual_router_name   = module.mesh_service.virtual_router_name
      virtual_node = {
        green = module.mesh_service.virtual_nodes["green"].node_name
      }
    }
    endpoint = {
      appmesh_virtual_service = "http://${module.mesh_service.virtual_service_name}:${local.app_service["mesh"]["route_listener"]["port"]}"
      appmesh_virtual_gateway = lookup(local.app_service["mesh"], "virtual_gateway_path", null) != null ? (
        "https://mesh-gateway.${var.environment}.aws-ue1.happymoney.com${local.app_service.mesh.virtual_gateway_path}"
      ) : ""
    }
  }
}

output "dynamodb_tables" {
  value = [
    for key, val in aws_dynamodb_table.table : val.name
  ]
}

output "datadog_monitors" {
  value = [
    for def in module.monitor_definitions.monitors : def.name
  ]
}