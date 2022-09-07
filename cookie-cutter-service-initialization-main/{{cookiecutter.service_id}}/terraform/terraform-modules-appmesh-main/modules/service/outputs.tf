output "cloud_map_service_id" {
  description = "Provisioned cloud map service id"
  value       = aws_service_discovery_service.cloudmap_service.id
}

output "cloud_map_service_arn" {
  description = "Provisioned cloud map service arn"
  value       = aws_service_discovery_service.cloudmap_service.arn
}

output "cloud_map_service_name" {
  description = "Provisioned cloud map service name"
  value       = aws_service_discovery_service.cloudmap_service.name
}

output "virtual_service_id" {
  description = "ID of the virtual service"
  value       = aws_appmesh_virtual_service.service.id
}

output "virtual_service_arn" {
  description = "ARN of the virtual service"
  value       = aws_appmesh_virtual_service.service.arn
}

output "virtual_service_name" {
  description = "Name of the virtual service"
  value       = aws_appmesh_virtual_service.service.name
}

output "virtual_router_id" {
  description = "ID of the virtual router"
  value       = aws_appmesh_virtual_router.router.id
}

output "virtual_router_arn" {
  description = "ARN of the virtual router"
  value       = aws_appmesh_virtual_router.router.arn
}

output "virtual_router_name" {
  description = "Name of the virtual router"
  value       = aws_appmesh_virtual_router.router.name
}

output "virtual_nodes" {
  description = "Map of virtual nodes provisioned"
  value       = module.virtual_nodes
}

output "virtual_routes" {
  description = "List of virtual routes provisioned for service"
  value = [
    for route in var.routes : aws_appmesh_route.service-route[route["path"]]
  ]
}

output "virtual_gateway_route" {
  description = "Virtual gateway route provisioned"
  value       = var.virtual_gateway_route == null ? null : aws_appmesh_gateway_route.gw_route
}