output "cloud_map_namespace" {
  description = "The Name of the cloud map namespace"
  value       = aws_service_discovery_private_dns_namespace.cloudmap.name
}

output "cloud_map_id" {
  description = "The ID of the cloud map namespace"
  value       = aws_service_discovery_private_dns_namespace.cloudmap.id
}

output "cloud_map_arn" {
  description = "The ID of the cloud map arn"
  value       = aws_service_discovery_private_dns_namespace.cloudmap.arn
}

output "cloud_map_hosted_zone" {
  description = "The ID of the hosted zone in aws route 53 created for the namespace."
  value       = aws_service_discovery_private_dns_namespace.cloudmap.hosted_zone
}

output "app_mesh_id" {
  description = "The ID of the service mesh"
  value       = aws_appmesh_mesh.mesh.id
}

output "app_mesh_arn" {
  description = "The ARN of the service mesh"
  value       = aws_appmesh_mesh.mesh.arn
}

output "cloud_map_acmpca_ca_arn" {
  description = "Certificate authority arn of cloudmap root acmpca"
  value       = var.cloudmap_tls_cert_enabled ? aws_acmpca_certificate_authority.rootcloudmap[0].arn : null
}

output "cloud_map_acmpca_arn" {
  description = "Certificate authority arn of cloudmap root acmpca certificate"
  value       = var.cloudmap_tls_cert_enabled ? aws_acmpca_certificate.certcloudmap[0].arn : null
}

output "cloud_map_acm_arn" {
  description = "ACM arn of cloudmap domain certificate"
  value       = var.cloudmap_tls_cert_enabled ? aws_acm_certificate.star_cloudmap_domain[0].arn : null
}