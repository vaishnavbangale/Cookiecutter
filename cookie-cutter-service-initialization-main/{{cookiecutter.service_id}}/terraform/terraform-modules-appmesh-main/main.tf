data "aws_caller_identity" "current" {}

#-------------------------------------------------------------------------
# Cloud map service discovery
resource "aws_service_discovery_private_dns_namespace" "cloudmap" {
  name        = var.cloudmap_namespace
  description = var.cloudmap_namespace_description
  vpc         = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name               = var.cloudmap_namespace
      terraform-resource = "aws_service_discovery_private_dns_namespace.cloudmap"
    }
  )
}

#-------------------------------------------------------------------------
# App mesh

resource "aws_appmesh_mesh" "mesh" {
  name = var.mesh_name

  spec {
    egress_filter {
      type = var.mesh_egress_filter
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = var.mesh_name
      terraform-resource = "aws_appmesh_mesh.mesh"
    }
  )
}