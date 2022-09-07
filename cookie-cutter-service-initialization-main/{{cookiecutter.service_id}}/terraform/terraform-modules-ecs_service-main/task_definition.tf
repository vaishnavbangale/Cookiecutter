resource "aws_ecs_task_definition" "application_task" {
  family                   = "${var.application_name}_${var.environment}"
  requires_compatibilities = [var.launch_type]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.exec.arn

  dynamic "volume" {
    for_each = var.container_volumes

    content {
      name = volume.value["name"]
      efs_volume_configuration {
        file_system_id          = volume.value["file_system_id"]
        root_directory          = lookup(volume.value, "efs_root_directory", null)
        transit_encryption      = lookup(volume.value, "transit_encryption", null)
        transit_encryption_port = lookup(volume.value, "transit_encryption_port", null)

        dynamic "authorization_config" {
          for_each = lookup(volume.value, "authorization_config", null) != null ? [volume.value["authorization_config"]] : []
          content {
            access_point_id = lookup(authorization_config.value, "access_point_id", null)
            iam             = lookup(authorization_config.value, "iam", null)
          }
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name               = "${var.application_name}${var.environment}ServerTaskDefinition"
      terraform-resource = "aws_ecs_task_definition.application_task"
    }
  )

  dynamic "proxy_configuration" {
    for_each = var.app_mesh_resource_arn == null || var.app_mesh_resource_type == "virtual_gateway" ? [] : [{
      container_name          = "envoy"
      container_service_ports = join(",", var.container_service_ports)
    }]
    content {
      type           = "APPMESH"
      container_name = proxy_configuration.value.container_name
      properties = {
        AppPorts         = proxy_configuration.value.container_service_ports
        EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
        IgnoredGID       = "1337"
        ProxyEgressPort  = 15001
        ProxyIngressPort = 15000
      }
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage > 20 ? toset([1]) : toset([])
    content {
      size_in_gib = var.ephemeral_storage
    }
  }

  container_definitions = var.app_mesh_resource_type == "virtual_gateway" ? (
    jsonencode(concat(local.container_def, local.dd_container_def))
    ) : (
    jsonencode(concat(local.envoy_container_def, local.dd_container_def, local.container_def))
  )
}