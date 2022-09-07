# Local variables
locals {
  # Region abbreviations and availability zones
  abbrv_map = {
    "us-east-1" = "ue1",
    "us-east-2" = "ue2",
    "us-west-1" = "uw1",
    "us-west-2" = "uw2"
  }
  region_abbrv = lookup(local.abbrv_map, var.region, null)
  availability_zones = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  default_protocol = {
    "alb" = "HTTP"
    "nlb" = "TCP"
  }

  #----------------------------------------------------------------
  # Parsed LB targets

  alb_targets = {
    for key, val in var.targets :
    key => val
    if val["lb_type"] == "alb"
  }

  nlb_targets = {
    for key, val in var.targets :
    key => val
    if val["lb_type"] == "nlb"
  }

  # Extract health check only ports
  unfiltered_hc_ports_map = {
    for key, val in var.targets : key => {
      port = lookup(lookup(val, "health_check", {}), "port", "traffic-port") == "traffic-port" ? val["port"] : val["health_check"]["port"]
    }
  }
  hc_ports_map = {
    for key, val in var.targets :
    key => val["health_check"]["port"]
    if lookup(lookup(val, "health_check", {}), "port", "traffic-port") != "traffic-port" && lookup(lookup(val, "health_check", {}), "port", "traffic-port") != val["port"]
  }

  #----------------------------------------------------------------
  # Container definition variables

  service_ports      = length(var.container_service_ports) > 0 ? var.container_service_ports : distinct([for key, val in var.targets : val["port"]])
  health_check_ports = distinct([for key, val in local.hc_ports_map : val])
  container_service_ports = [for port in distinct(concat(local.service_ports, local.health_check_ports)) :
    {
      "containerPort" : port,
      "hostPort" : port,
      "protocol" : "tcp"
    }
  ]
  container_port_mapping = jsonencode(local.container_service_ports)
  dd_tags                = replace(jsonencode(merge({ project = var.application_name, env = var.environment }, var.dd_tags)), "/[\\{\\}\"\\s]/", "")
  dd_service             = var.dd_service == "" ? var.application_name : var.dd_service
  app_image              = var.challenger_environment == "" ? "${var.ecr_repo_url}:${var.environment}" : "${var.ecr_repo_url}:${var.challenger_environment}"
  application_source     = var.application_source == null ? var.application_name : var.application_source
  container_healthcheck  = lookup(var.container_healthcheck, "Command", null) == null ? "null" : jsonencode(var.container_healthcheck)
  container_log_options = var.container_cw_log_group == null ? {
    "logDriver" = "awsfirelens"
    "options" : {
      "Name"       = "datadog"
      "apiKey"     = data.aws_ssm_parameter.dd_api_key.value
      "dd_service" = local.dd_service
      "dd_source"  = local.application_source
      "dd_tags"    = local.dd_tags
      "TLS"        = "on"
      "provider"   = "ecs"
    }
    } : {
    "logDriver" = "awslogs",
    "options" = {
      "awslogs-group"         = var.container_cw_log_group,
      "awslogs-region"        = var.region
      "awslogs-stream-prefix" = local.dd_service
    }
  }
  container_log_configuration = "\"logConfiguration\": ${jsonencode(local.container_log_options)},"

  #---------------------
  # envoy sidecar variables

  envoy_healthcheck = jsonencode(merge({
    "command" = [
      "CMD-SHELL",
      "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"
    ]
    "startPeriod" = 10
    "interval"    = 5
    "timeout"     = 2
    "retries"     = 3
  }, var.envoy_healthcheck))
  envoy_ecs_container_name = "envoy"
  envoy_application_name   = var.dd_service == "" ? "${var.application_name}-envoy" : "${var.dd_service}-envoy"
  envoy_log_options = var.envoy_cw_log_group == null ? {
    "logDriver" = "awsfirelens"
    "options" : {
      "Name"       = "datadog"
      "apiKey"     = data.aws_ssm_parameter.dd_api_key.value
      "dd_service" = local.envoy_application_name,
      "dd_source"  = local.envoy_ecs_container_name
      "dd_tags"    = local.dd_tags
      "TLS"        = "on"
      "provider"   = "ecs"
    }
    } : {
    "logDriver" = "awslogs",
    "options" = {
      "awslogs-group"         = var.envoy_cw_log_group,
      "awslogs-region"        = var.region,
      "awslogs-stream-prefix" = local.envoy_application_name
    }
  }
  envoy_log_configuration = "\"logConfiguration\": ${jsonencode(local.envoy_log_options)},"
  envoy_dd_unified_serv_tag_env_vars = [
    {
      "name" : "DD_SERVICE",
      "value" : local.envoy_application_name
    },
    {
      "name" : "DD_ENV",
      "value" : var.environment
    }
  ]
  envoy_sidecar_environment_variables = concat(local.envoy_env_vars, local.envoy_dd_unified_serv_tag_env_vars)
  #---------------------
  # environment variables

  envoy_env_vars = var.app_mesh_resource_type != "" ? jsondecode(templatefile("${path.module}/templates/envoy_env_variables.json.tmpl", {
    app_mesh_resource_arn = var.app_mesh_resource_arn
    envoy_log_level       = var.envoy_log_level
  })) : []
  dd_unified_serv_tag_env_vars = [
    {
      "name" : "DD_SERVICE",
      "value" : local.dd_service
    },
    {
      "name" : "DD_ENV",
      "value" : var.environment
    }
  ]
  container_env_vars = var.app_mesh_resource_type == "virtual_gateway" ? (
    jsonencode(concat(local.envoy_env_vars, local.dd_unified_serv_tag_env_vars, var.environment_variables))
  ) : jsonencode(concat(local.dd_unified_serv_tag_env_vars, var.environment_variables))

  #---------------------
  # docker labels
  ad_logs_docker_label = var.log_files_enabled == true ? {
    "com.datadoghq.ad.logs" = "[{\"type\":\"docker\",\"source\":\"${local.application_source}\",\"service\":\"${local.dd_service}\"}]"
  } : {}
  appmesh_docker_label = var.app_mesh_resource_type != "" ? {
    "com.datadoghq.ad.instances"    = "[{\"stats_url\": \"http://%%host%%:9901/stats\"}]",
    "com.datadoghq.ad.check_names"  = "[\"envoy\"]",
    "com.datadoghq.ad.init_configs" = "[{}]"
  } : {}
  container_unified_serv_docker_label = merge({
    "com.datadoghq.tags.env"     = var.environment
    "com.datadoghq.tags.service" = local.dd_service
  }, local.appmesh_docker_label, var.container_docker_labels)
  dd_agent_unified_serv_docker_label = merge({
    "com.datadoghq.tags.env"     = var.environment
    "com.datadoghq.tags.service" = local.dd_service
  }, local.ad_logs_docker_label, local.appmesh_docker_label, var.datadog_docker_labels)
  envoy_unified_serv_docker_label = merge({
    "com.datadoghq.tags.env"     = var.environment
    "com.datadoghq.tags.service" = local.envoy_application_name
  }, local.appmesh_docker_label, var.envoy_docker_labels)

  #---------------------
  envoy_depends_on = var.app_mesh_resource_type != "" && var.app_mesh_resource_type != "virtual_gateway" ? jsonencode([{
    "containerName" : "envoy",
    "condition" : "HEALTHY"
  }]) : "null"
  ulimits = var.app_mesh_resource_type == "virtual_gateway" && var.ulimits == -1 ? 15000 : var.ulimits

  #-------------------------------------------------------------------------------
  # Container definition components

  # App container
  container_def = jsondecode(templatefile("${path.module}/templates/container.json.tmpl", {
    application_name         = var.application_name
    application_source       = local.application_source
    ecs_container_image      = var.app_mesh_resource_type == "virtual_gateway" ? var.envoy_image : var.app_image != null ? var.app_image : local.app_image
    user                     = var.app_mesh_resource_type == "virtual_gateway" ? "\"1337\"" : "null"
    dockerLabels             = local.container_unified_serv_docker_label == {} ? "null" : jsonencode(local.container_unified_serv_docker_label)
    container_cpu            = var.container_cpu - 256
    container_memory         = var.container_memory - 512
    task_start_commands      = var.task_start_commands == null ? "null" : jsonencode(var.task_start_commands)
    task_entrypoint_commands = var.task_entrypoint_commands == null ? "null" : jsonencode(var.task_entrypoint_commands)
    container_stop_timeout   = var.container_stop_timeout == -1 ? "null" : var.container_stop_timeout
    environment_variables    = local.container_env_vars
    secret_variables         = jsonencode(var.secret_variables)
    environmentFiles = jsonencode(flatten([
      for path in var.environmentfile_bucket_paths :
      {
        value = "${path.arn}/${path.key_name}"
        type  = "s3"
      }
    ]))
    mountPoints = jsonencode(flatten([
      for volume in var.container_volumes :
      {
        sourceVolume  = volume.name,
        containerPath = volume.container_path,
      }
    ]))
    ulimits = local.ulimits == -1 ? "null" : jsonencode([
      {
        "name" : "nofile",
        "softLimit" : local.ulimits,
        "hardLimit" : local.ulimits
      }
    ])
    linux_parameters            = var.linux_parameters == "" ? "null" : var.linux_parameters
    container_port_mapping      = local.container_port_mapping
    depends_on                  = local.envoy_depends_on
    apiKey                      = data.aws_ssm_parameter.dd_api_key.value
    dd_tags                     = local.dd_tags
    healthcheck                 = var.app_mesh_resource_type == "virtual_gateway" ? local.envoy_healthcheck : local.container_healthcheck
    container_log_configuration = local.container_log_configuration
  }))

  # Datadog agent and log collection containers
  dd_container_def = jsondecode(templatefile("${path.module}/templates/datadog.json.tmpl", {
    application_name      = var.application_name
    environment           = var.environment
    dockerLabels          = local.dd_agent_unified_serv_docker_label == {} ? "null" : jsonencode(local.dd_agent_unified_serv_docker_label)
    log_files_enabled     = var.log_files_enabled
    region                = var.region
    account_id            = var.account_id
    credentialsParameter  = data.aws_secretsmanager_secret.dockerhub.arn
    fluentbit_version     = var.fluentbit_version
    datadog_agent_version = var.datadog_agent_version
    fluentbit_config_file = var.fluentbit_config_file
  }))

  # App mesh envoy sidecar container
  envoy_container_def = var.app_mesh_resource_type == "virtual_node" ? jsondecode(templatefile("${path.module}/templates/envoy.json.tmpl", {
    envoy_image             = var.envoy_image
    envoy_log_configuration = local.envoy_log_configuration
    app_mesh_resource_arn   = var.app_mesh_resource_arn
    envoy_log_level         = var.envoy_log_level
    envoy_healthcheck       = local.envoy_healthcheck
    dockerLabels            = local.envoy_unified_serv_docker_label == {} ? "null" : jsonencode(local.envoy_unified_serv_docker_label)
    environment_variables   = jsonencode(local.envoy_sidecar_environment_variables)
    ecs_container_name      = local.envoy_ecs_container_name
  })) : []
}
