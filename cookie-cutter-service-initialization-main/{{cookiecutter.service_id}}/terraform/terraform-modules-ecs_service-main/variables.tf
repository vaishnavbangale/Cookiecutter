variable "log_files_enabled" {
  type    = bool
  default = false
}

variable "task_entrypoint_commands" {
  type        = list(string)
  default     = null
  description = "Entrypoint command for the ecs task definition"
}

variable "task_start_commands" {
  type        = list(string)
  description = "Start command for the ecs task definition"
  default     = null
}

variable "environment" {
  type = string
}

variable "application_name" {
  type = string
}

variable "application_source" {
  type        = string
  description = "Human readable name for the underlying technology of service. e.g. postgres, nginx. Used in datadog log collection configuration."
  default     = null
}

variable "ecs_cluster_id" {
  type = string
}

variable "network_access_cidrs" {
  type    = list(string)
  default = []
}

variable "private_access_cidrs" {
  type    = list(string)
  default = []
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "load_balancer_subnet_ids" {
  type    = list(string)
  default = null
}

variable "ulimits" {
  type    = number
  default = -1
}

variable "container_service_ports" {
  type    = list(number)
  default = []
}

variable "container_cw_log_group" {
  type    = string
  default = null
}

variable "targets" {
  description = "Map of LB targets to associate with the service"
  default     = {}
}

variable "vpc_cidr" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "The aws region"
}

variable "launch_type" {
  type    = string
  default = "FARGATE"
}

variable "deploy_max_percent" {
  type    = number
  default = 200
}

variable "deploy_min_percent" {
  type    = number
  default = 100
}

variable "instance_type_spot" {
  type    = string
  default = "c5.2xlarge"
}

variable "constraint_type" {
  type    = list(any)
  default = []
}

variable "ecr_repo_arn" {
  type    = string
  default = ""
}

variable "ecr_repo_url" {
  type    = string
  default = ""
}

variable "account_id" {
  type        = string
  description = "aws account id"
}

variable "dd_tags" {
  type        = map(string)
  description = "Datadog tags"
  default     = {}
}

variable "dd_service" {
  type        = string
  description = "Datadog service name"
  default     = ""
}

variable "container_cpu" {
  type    = number
  default = 512
}

variable "container_memory" {
  type    = number
  default = 1024
}

variable "container_volumes" {
  type    = list(any)
  default = []
}

variable "container_stop_timeout" {
  type        = number
  default     = -1
  description = "Time duration in seconds to wait before container is forcefully killed if it doesn't exit normally on its own."
}

variable "ecs_alarms_cpu_low_threshold" {
  type        = number
  default     = 20
  description = "If the average CPU utilization over a minute drops to this threshold, the number of containers will be reduced (but not below min_capacity)."
}

variable "ecs_alarms_cpu_high_threshold" {
  type        = number
  default     = 70
  description = "If the average CPU utilization over a minute rises to this threshold, the number of containers will be increased (but not above max_capacity)."
}

variable "ecs_alarms_memory_low_threshold" {
  type        = number
  default     = 30
  description = "If the average memory utilization over a minute drops to this threshold, the number of containers will be reduced (but not below min_capacity)."
}

variable "ecs_alarms_memory_high_threshold" {
  type        = number
  default     = 70
  description = "If the average memory utilization over a minute rises to this threshold, the number of containers will be increased (but not above max_capacity)."
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of containers for autoscaling"
  default     = 3
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of containers for autoscaling"
  default     = 1
}

variable "enable_autoscaling" {
  type        = bool
  description = "Whether to enable or disable autoscaling"
  default     = true
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the app. The name will be appended with prefix ecs-cluster- and a suffix of -environment_name-ue1"
}

variable "environmentfile_bucket_paths" {
  type = list(object({
    arn      = string
    key_name = string
  }))
  default     = []
  description = "S3 path to the environment files for the app"
}

variable "environmentfile_kms_arn" {
  type    = string
  default = ""
}

variable "service_registries" {
  description = "List of map containing registry_arn and port"
  default     = []
}

variable "ecs_task_role_policy" {
  type        = string
  default     = null
  description = "Custom IAM policy for ecs task role"
}

variable "ecs_task_role_extra_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of extra built-in or custom policy arns to attach to ecs exec role"
}

variable "ecs_exec_role_policy" {
  type        = string
  default     = null
  description = "Custom IAM policy for ecs exec role"
}

variable "ecs_exec_role_extra_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of extra built-in or custom policy arns to attach to ecs exec role"
}

variable "app_mesh_resource_arn" {
  type    = string
  default = null
}

variable "app_mesh_resource_type" {
  type        = string
  description = "The resource type of the app mesh resource. Supports virtual_node or virtual_gateway"
  default     = ""
}

variable "envoy_ecr_repo_arn" {
  type    = string
  default = "arn:aws:ecr:us-east-1:840364872350:repository/aws-appmesh-envoy"
}

variable "envoy_image" {
  type    = string
  default = ""
}

variable "envoy_log_level" {
  type    = string
  default = "error"
}

variable "envoy_cw_log_group" {
  type    = string
  default = null
}

variable "envoy_healthcheck" {
  description = "Envoy container health check overrides"
  default     = {}
}

variable "environment_variables" {
  default     = []
  description = "List of environment variable maps with name and value attributes for the container"
}

variable "secret_variables" {
  default     = []
  description = "List of secrets variable maps with name and valueFrom attributes for the container"
}

variable "short_application_name" {
  type        = string
  default     = ""
  description = "Optional short name for the application to deal with TG name size limit"
}

variable "linux_parameters" {
  type    = string
  default = ""
}

variable "challenger_environment" {
  type    = string
  default = ""
}

variable "container_healthcheck" {
  description = "Application container health check overrides"
  default     = {}
}

variable "fluentbit_version" {
  type        = string
  description = "Fluentbit sidecar image tag"
  default     = "stable"
}

variable "datadog_agent_version" {
  type        = string
  description = "Datadog agent sidecar image tag"
  default     = "7.32.3"
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Grace period to wait before beginning health check in seconds"
  default     = null
}

variable "container_docker_labels" {
  type        = map(string)
  description = "Docker labels to apply to container."
  default     = {}
}

variable "datadog_docker_labels" {
  type        = map(string)
  description = "Docker labels to apply to datadog agent container."
  default     = {}
}

variable "envoy_docker_labels" {
  type        = map(string)
  description = "Docker labels to apply to appmesh envoy container."
  default     = {}
}

variable "deployment_circuit_breaker" {
  type        = map(any)
  description = "Configuration for ECS deployment circuit breaker option"
  default     = null
}

variable "propagate_tags" {
  type        = string
  description = "Specify whether to propagate the tags from task definition or service for ECS service tasks."
  default     = null
}

variable "permissions_boundary" {
  type        = string
  description = "IAM permissions boundary arn to set the permissions boundary on exec and task roles."
  default     = null
}

variable "enable_execute_command" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec, to exec into the tasks, for the tasks within the service."
  default     = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional list of security group ids to attach to the ecs service."
  default     = []
}

variable "fluentbit_config_file" {
  type        = string
  description = "Fluentbit conf file name. Allowed values: minimize-log-loss|parse-json."
  default     = "parse-json"

  validation {
    condition     = contains(["minimize-log-loss", "parse-json"], var.fluentbit_config_file)
    error_message = "The fluentbit_config_file value must be either minimize-log-loss or parse-json."
  }
}

variable "app_image" {
  type        = string
  description = "App image url. Default is 'ecr_repo_url:environment'"
  default     = null
}

variable "capacity_provider_strategies" {
  default     = []
  description = "FARGATE, FARGATE_SPOT or a mix/both (spot vs on-demand pricing)"
}

variable "ephemeral_storage" {
  type        = number
  description = "Ephemeral storage to provision. Must be between 20 and 200"
  default     = 20

  validation {
    condition     = var.ephemeral_storage >= 20 && var.ephemeral_storage <= 200
    error_message = "The ephemeral_storage value must be between 20 and 200."
  }
}