locals {
  app_service                     = jsondecode(file("${path.module}/config.json"))
  environment_vars                = {}
  ecs_task_role_extra_policy_arns = length(local.task_policy_statements) > 0 ? [aws_iam_policy.task_role_extra_permissions[0].arn] : []
  ecs_exec_role_extra_policy_arns = []

  ecs_task_extra_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = local.task_policy_statements
  })

  task_policy_statements = concat(
    local.dynamodb_kms_statements,
    local.dynamodb_statements
  )

  dynamodb_kms_statements = length(local.app_service.dynamodb_tables) > 0 ? (
    [
      {
        "Sid" : "DynamoDBKMSAccess",
        "Effect" : "Allow",
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:CreateGrant",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : [
          for key, val in aws_kms_key.dynamodb : val.arn
        ]
      }
    ]
  ) : []

  dynamodb_statements = length(local.app_service.dynamodb_tables) > 0 ? (
    [
      {
        "Sid" : "DynamoDBAccess",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchGetItem",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:BatchWriteItem"
        ],
        "Resource" : flatten([
          for key, val in aws_dynamodb_table.table : [
            val.arn,
            "${val.arn}/index/*"
          ]
        ])
      }
    ]
  ) : []
}

#---------------------------------------------------------------------------------------
# Services
module "ecs_green" {
  source = "../../terraform-modules-ecs_service-main"

  application_name        = "${local.app_service.service_name}-green"
  short_application_name  = lookup(local.app_service.ecs_settings, "short_application_name", null) != null ? local.app_service.ecs_settings.short_application_name : ""
  container_service_ports = local.app_service.ecs_settings["container_service_ports"]
  dd_tags = {
    project = "${local.app_service.service_name}-green"
  }
  network_access_cidrs     = local.app_service.ecs_settings["network_access_cidrs"]
  task_start_commands      = lookup(local.app_service.ecs_settings, "task_start_commands", null)
  task_entrypoint_commands = lookup(local.app_service.ecs_settings, "task_entrypoint_commands", null)
  container_cpu            = local.app_service.ecs_settings["container_cpu"]
  container_memory         = local.app_service.ecs_settings["container_memory"]
  max_capacity             = local.app_service.ecs_settings["max_capacity"]
  min_capacity             = local.app_service.ecs_settings["min_capacity"]
  container_volumes        = []
  fluentbit_config_file    = lookup(local.app_service.ecs_settings, "fluentbit_config_file", "parse-json")

  targets = {
    for key, val in lookup(local.app_service.ecs_settings, "targets", {}) :
    key => merge(val, {
      listener_arn                    = module.lookup_map_ue1.network.alb.private.listener_arn
      load_balancer_arn               = module.lookup_map_ue1.network.alb.private.arn
      load_balancer_security_group_id = sort(module.lookup_map_ue1.network.alb.private.security_group)[0]
    })
  }
  capacity_provider_strategies = local.app_service.ecs_settings["capacity_provider_strategies"]

  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  propagate_tags     = "SERVICE"
  ecs_cluster_id     = module.lookup_map_ue1.ecs_cluster.infrafargate
  ecs_cluster_name   = split("/", module.lookup_map_ue1.ecs_cluster.infrafargate)[1]
  envoy_ecr_repo_arn = local.app_service.ecs_settings["envoy_ecr_arn"]
  ecr_repo_arn       = local.app_service.ecs_settings["ecr_repo_arn"]
  ecr_repo_url       = local.app_service.ecs_settings["ecr_repo_url"]
  subnet_ids = [
    module.lookup_map_ue1.network.priv_subnet_id.a,
    module.lookup_map_ue1.network.priv_subnet_id.b,
    module.lookup_map_ue1.network.priv_subnet_id.c
  ]
  private_access_cidrs = [
    data.aws_subnet.priv_us_east_1a_subnet.cidr_block,
    data.aws_subnet.priv_us_east_1b_subnet.cidr_block,
    data.aws_subnet.priv_us_east_1c_subnet.cidr_block
  ]
  vpc_id   = module.lookup_map_ue1.network.vpc_id
  vpc_cidr = [module.lookup_map_ue1.network.vpc_cidr]
  tags = merge(
    {
      hm-service       = local.app_service.service_name
      terraform-module = "module.ecs_green"
      env              = var.environment
      public-facing    = false
    },
    lookup(local.app_service, "tags", {})
  )
  environmentfile_bucket_paths = lookup(local.app_service.ecs_settings, "env_file_bucket_arn", "") != "" ? [
    {
      arn      = local.app_service.ecs_settings.env_file_bucket_arn
      key_name = "${var.environment}/${var.app_name}/${lookup(local.app_service.ecs_settings, "env_file_name", "${local.app_service.service_name}.env")}",
    }
  ] : []
  environmentfile_kms_arn          = lookup(local.app_service.ecs_settings, "env_file_kms_arn", "")
  environment_variables            = concat(lookup(local.app_service.ecs_settings, "environment_variables", []), lookup(local.environment_vars, local.app_service.service_name, []))
  secret_variables                 = lookup(local.app_service.ecs_settings, "secret_variables", [])
  environment                      = var.environment
  region                           = data.aws_region.current.name
  account_id                       = data.aws_caller_identity.current.account_id
  ecs_alarms_cpu_low_threshold     = lookup(local.app_service.ecs_settings, "ecs_alarms_cpu_low_threshold", 20)
  ecs_alarms_cpu_high_threshold    = lookup(local.app_service.ecs_settings, "ecs_alarms_cpu_high_threshold", 70)
  ecs_alarms_memory_low_threshold  = lookup(local.app_service.ecs_settings, "ecs_alarms_memory_low_threshold", 30)
  ecs_alarms_memory_high_threshold = lookup(local.app_service.ecs_settings, "ecs_alarms_memory_high_threshold", 70)
  service_registries = [
    for port in local.app_service.ecs_settings["container_service_ports"] :
    {
      registry_arn = module.mesh_service.cloud_map_service_arn
      port         = port
      record_type  = "SRV"
    }
  ]
  envoy_image     = local.app_service.ecs_settings.envoy_image
  envoy_log_level = lookup(local.app_service.ecs_settings, "envoy_log_level", "warning")
  envoy_healthcheck = merge({
    interval = 20
    retries  = 5
    timeout  = 5
  }, lookup(local.app_service.ecs_settings, "envoy_healthcheck", {}))
  app_mesh_resource_arn  = module.mesh_service.virtual_nodes["green"]["node_arn"]
  app_mesh_resource_type = "virtual_node"

  ecs_task_role_extra_policy_arns = local.ecs_task_role_extra_policy_arns
  ecs_exec_role_extra_policy_arns = local.ecs_exec_role_extra_policy_arns

  permissions_boundary = lookup(local.app_service.ecs_settings, "permission_boundary_name", null) != null ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/devops/${local.app_service.ecs_settings.permission_boundary_name}" : null

  depends_on = [module.mesh_service]
}

# Appmesh
module "mesh_service" {
  source = "../../terraform-modules-appmesh-main"

  cloudmap_namespace = data.aws_service_discovery_dns_namespace.mesh.name
  app_mesh_id        = data.aws_appmesh_mesh.mesh.id
  name               = local.app_service.service_name
  health_check_custom_config = lookup(local.app_service, "health_check_custom_config", {
    failure_threshold = 3
  })
  router_port_mapping = {
    port     = local.app_service["mesh"]["route_listener"]["port"]
    protocol = local.app_service["mesh"]["route_listener"]["protocol"]
  }
  nodes = {
    for node in local.app_service["mesh"]["nodes"] : node => {
      cloud_map_service_discovery = {
        attributes = {
          ECS_TASK_DEFINITION_FAMILY = "${lookup(local.app_service.ecs_settings, "service_name", local.app_service.service_name)}-${node}_${var.environment}"
        }
      }
      listeners        = [for listener in local.app_service["mesh"]["listeners"] : merge(listener, { tls = local.tls })]
      backends         = local.app_service["mesh"]["backends"]
      backend_defaults = local.backend_defaults
    }
  }
  http_service_route_retry_enabled = lookup(local.app_service.mesh, "http_service_route_retry_enabled", true)
  routes                           = local.app_service["mesh"]["routes"]
  virtual_gateway_route = lookup(local.app_service["mesh"], "virtual_gateway_path", null) != null ? {
    virtual_gateway_name = lookup(local.app_service["mesh"], "virtual_gateway_name", "mesh-gateway")
    match_prefix         = local.app_service["mesh"]["virtual_gateway_path"]
  } : null
  tags = merge(
    {
      hm-service       = local.app_service.service_name
      terraform-module = "module.mesh_service"
      env              = var.environment
      public-facing    = false
    },
    lookup(local.app_service, "tags", {})
  )
}

# Additional Task role policy
resource "aws_iam_policy" "task_role_extra_permissions" {
  count = length(local.task_policy_statements) > 0 ? 1 : 0

  name        = "iam-pol-ecs-task-${var.app_name}-${local.app_service.service_name}-${var.environment}-extra"
  description = "Policy to grant access to ${var.app_name} ${local.app_service.service_name} service extra permissions"
  policy      = local.ecs_task_extra_role_policy

  tags = merge(
    {
      Name               = "iam-pol-ecs-task-${var.app_name}-${local.app_service.service_name}-${var.environment}-extra"
      hm-service         = local.app_service.service_name
      terraform-resource = "aws_iam_policy.task_role_extra_permissions"
      env                = var.environment
      public-facing      = false
    },
    lookup(local.app_service, "tags", {})
  )
}

# dynamodb
resource "aws_kms_key" "dynamodb" {
  count                   = length(local.app_service.dynamodb_tables) > 0 ? 1 : 0
  description             = "KMS key for ${local.app_service.service_name} dynamodb ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    {
      hm-service         = local.app_service.service_name
      terraform-resource = "aws_kms_key.dynamodb"
      env                = var.environment
      public-facing      = false
    },
    lookup(local.app_service, "tags", {})
  )
}

resource "aws_dynamodb_table" "table" {
  for_each     = local.app_service.dynamodb_tables
  name         = "dyndb-table-${each.key}-${var.environment}-${module.lookup_map_ue1.region_abbrv}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = each.value.hash_key
  range_key    = lookup(each.value, "range_key", null)

  dynamic "attribute" {
    for_each = lookup(each.value, "attributes", []) == [] ? (
      [{
        name = each.value.hash_key
        type = "S"
    }]) : each.value["attributes"]
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = lookup(each.value, "global_secondary_index", {})
    content {
      name            = global_secondary_index.key
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = global_secondary_index.value.projection_type
    }
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb[0].arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    {
      hm-service         = local.app_service.service_name
      terraform-resource = "aws_dynamodb_table.table"
      env                = var.environment
      public-facing      = false
    },
    lookup(local.app_service, "tags", {})
  )
}