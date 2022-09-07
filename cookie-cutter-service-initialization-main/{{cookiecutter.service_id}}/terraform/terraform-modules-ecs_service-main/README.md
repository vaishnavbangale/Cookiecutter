## terraform-modules-ecs_service ##
NOTE: When migrating from v2 to v3 there is a need to deploy twice due to autoscaling resources not getting applyed during the first run.

# usage #
```hcl
module "ecs_service" {
  source           = "git@github.com:HappyMoneyInc/terraform-modules-ecs_service.git?ref=v3.5.0"
  capacity_provider_strategies = [{
    capacity_provider = "FARGATE"
    weight            = 1
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 9
      base              = 1
  }]

  task_start_commands  = []
  environment          = "sandbox"
  application_name     = "example"
  ecs_cluster_id       = "arn:aws:ecs:us-east-1:512436868621:cluster/ecs-cluster-infraFargate-sandbox-ue1"
  network_access_cidrs = ["10.208.0.0/16"]
  subnet_ids = [
    data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id,
    data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id,
  ]
  targets = {
    "app_service" = {
      port                            = 80
      priority                        = 10
      service_paths                   = ["/*"]
      host_headers                    = ["example.sandbox.aws-ue1.happymoney.com"]
      lb_type                         = "alb"
      listener_arn                    = module.alb.listener_arn
      load_balancer_arn               = module.alb.load_balancer_arn
      load_balancer_security_group_id = module.alb.load_balancer_security_group_id
      health_check = {
        enabled = true
        path    = "/health"
      }
    }
  }
  vpc_cidr                        = ["10.208.0.0/16"]
  vpc_id                          = "vpc-03207458f7f9b482e"
  desired_count                   = 1
  tags                            = {}
  region                          = "us-east-1"
  launch_type                     = "FARGATE"
  ecr_repo_arn                    = "arn:aws:ecr:us-east-1:840364872350:repository/aws-appmesh-envoy"
  ecr_repo_url                    = "840364872350.dkr.ecr.us-east-1.amazonaws.com/aws-appmesh-envoy:v1.17.2.0-prod"
  account_id                      = "512436868621"
  dd_tags = {
    "project" = "ecs-service-example",
    "env"     = "sandbox"
  }
  container_cpu                 = 512
  container_memory              = 1024
  container_volumes             = []
  ecs_as_cpu_low_threshold_per  = "20"
  ecs_as_cpu_high_threshold_per = "70"
  max_capacity                  = 3
  min_capacity                  = 1
  ecs_cluster_name              = local.cluster_name
  linux_parameters              = "{ \"initProcessEnabled\": true }"
  environmentfile_bucket_paths  = []
  environmentfile_kms_arn       = ""
  ephemeral_storage             = 20

  # To Enable 100% FARGATE_SPOT
  capacity_provider_strategies = [{
    capacity_provider = "FARGATE"
    weight            = 1
    },
    {
      capacity_provider = "FARGATE_SPOT"
      weight            = 9
      base              = 1 # or like: local.app_service.ecs_settings["min_capacity"]
  }]

  ecs_task_role_policy          = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "ecr:GetAuthorizationToken",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}
```

#

```hcl

```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| log_files_enabled | Flag to enable DD_LOGS_ENABLED | bool | `false` | no |
| task_entrypoint_commands | Entrypoint command for the ecs task definition | list(string) | `null` | no |
| task_start_commands | Start command for the ecs task definition | list(string) | `null` | no |
| environment | Environment name | string | n/a | yes |
| application_name | App name | string | n/a | yes |
| application_source | Human readable name for the underlying technology of service (e.g. postgres, nginx). Used in datadog log collection configuration. | string | `null` | no |
| capacity_provider_strategies | FARGATE, FARGATE_SPOT or a mix/both (spot vs on-demand pricing) | list(map) | `[]` | no |
| ecs_cluster_id | Target ECS cluster id to deploy service | string | n/a | yes |
| ecs_cluster_name | Target ECS cluster name | string | n/a | yes |
| network_access_cidrs | CIDR blocks to allow ingress access from | list(string) | `[]` | no |
| private_access_cidrs | CIDR blocks to allow ingress access from service discovery | list(string) | `[]` | no |
| subnet_ids | List of subnet ids to map | list(string) | `[]` | no |
| ulimits |  | number | `-1` | no |
| container_service_ports | Container service ports that the container uses. Does not need to be passed if using 'targets'. | list(number) | `[]` | no |
| targets | Map of service targets to associate with the service. See targets block properties below. | map | `{}` | no |
| vpc_cidr | CIDR block of vpc | list(string) | `[]` | no |
| vpc_id | VPC id for service network configuration | string | n/a | yes |
| desired_count | ECS service desired count | number | `1` | no |
| tags | Common tags to associate with resources created | map(string) | n/a | yes |
| region | Target group unhealthy threshold | string | `us-east-1` | no |
| launch_type | ECS service launch type | string | `FARGATE` | no |
| deploy_max_percent | Deployment maximum percent | number | `200` | no |
| deploy_min_percent | Deployment minimum healthy percent | number | `100` | no |
| health_check_grace_period_seconds | Grace period to wait before starting health checks | string | null | no |
| constraint_type | Placement constraints | list | `[]` | no |
| ecr_repo_arn | ECR repository ARN | string | `""` | no |
| ecr_repo_url | ECR repository Url | string | `""` | no |
| account_id | Target AWS account ID | string | n/a | yes |
| dd_tags | Datadog tags. By default project and env are already included. | map(string) | `{}` | no |
| dd_service | **Optional** Datadog service name. | string | `""` | no |
| container_cpu | Container CPU | number | `512` | no |
| container_memory | Container Memory | number | `1024` | no |
| container_volumes | List of container volumes | list | `[]` | no |
| container_cw_log_group | App container target cloudwatch log group | string | `null` | no |
| container_stop_timeout | Time duration in seconds to wait before container is forcefully killed if it doesn't exit normally on its own. -1 to use default. | number | `-1` | no |
| ecs_alarms_cpu_low_threshold | If the average CPU utilization over a minute drops to this threshold, the number of containers will be reduced (but not below min_capacity). | number | `20` | no |
| ecs_alarms_cpu_high_threshold | If the average CPU utilization over a minute rises to this threshold, the number of containers will be increased (but not above max_capacity). | number | `70` | no |
| ecs_alarms_memory_low_threshold | If the average memory utilization over a minute drops to this threshold, the number of containers will be reduced (but not below min_capacity). | number | `30` | no |
| ecs_alarms_memory_high_threshold | If the average memory utilization over a minute rises to this threshold, the number of containers will be increased (but not above max_capacity). | number | `70` | no |
| max_capacity | Maximum number of containers for autoscaling | number | `3` | no |
| min_capacity | Minimum number of containers for autoscaling | number | `1` | no |
| enable_autoscaling | Whether to enable or disable autoscaling | bool | `true` | no |
| environmentfile_bucket_paths | S3 path to the environment files for the app | list(object) | `[]` | no |
| environmentfile_kms_arn | KMS arn used to encrypt environment bucket files | string | `""` | no |
| service_registries | List of map containing registry_arn and port if using cloud map | list | `[]` | no |
| ecs_task_role_policy | Custom IAM policy to use for ecs task role | string | `null` | no |
| ecs_task_role_extra_policy_arns | List of extra built-in or custom policy arns to attach to ecs task role | list(string) | `[]` | no |
| ecs_exec_role_policy | Custom IAM policy to use for ecs exec role | string | `null` | no |
| ecs_exec_role_extra_policy_arns | List of extra built-in or custom policy arns to attach to ecs exec role | list(string) | `[]` | no |
| app_mesh_resource_arn | App mesh resource arn to pass into envoy sidecar container variables | string | `null` | no |
| app_mesh_resource_type | The resource type of the app mesh resource. Supports virtual_node or virtual_gateway | string | `""` | no |
| envoy_ecr_repo_arn | Envoy image ECR arn | string | `arn:aws:ecr:us-east-1:840364872350:repository/aws-appmesh-envoy` | no |
| envoy_image | Envoy image url | string | `null` | no |
| envoy_log_level | Envoy container log level | string | `error` | no |
| envoy_cw_log_group | Envoy container target cloudwatch log group | string | `null` | no |
| envoy_healthcheck | Envoy container health check overrides | map | `{}` | no |
| environment_variables | List of environment variable maps with name and value attributes for the container | list | `[]` | no |
| secret_variables | List of secrets variable maps with name and valueFrom attributes for the container | list | `[]` | no |
| short_application_name | **Optional** short name for the application to deal with TG name size limit | string | `""` | no |
| linux_parameters | **Optional** passing of Linux Parameters from the task definition to the container | string | `""` | no |
| challenger_environment | **Optional** flag for challenger environment | string | `""` | no |
| container_healthcheck | **Optional** ECS container health check | map | `{}` | no |
| fluentbit_version | **Optional** aws-for-fluent-bit sidecar image tag | string | `stable` | no |
| datadog_agent_version | **Optional** datadog agent sidecar image tag | string | `7.30.1` | no |
| container_docker_labels | Docker labels to apply to container. | map(string) | `{}` | no |
| datadog_docker_labels | Docker labels to apply to datadog agent container. | map(string) | `{}` | no |
| envoy_docker_labels | Docker labels to apply to appmesh envoy container. | map(string) | `{}` | no |
| deployment_circuit_breaker | Configuration for ECS deployment circuit breaker option. | map(any) | `null` | no |
| propagate_tags | Specify whether to propagate the tags from TASK_DEFINITION or SERVICE for ECS service tasks.| string | `null` | no |
| permissions_boundary | IAM permissions boundary arn to set the permissions boundary on exec and task roles. | string | `null` | no |
| enable_execute_command | Specifies whether to enable Amazon ECS Exec, to exec into the tasks, for the tasks within the service. | bool | `false` | no |
| security_group_ids | Additional list of security group ids to attach to the ecs service. | list(string) | `[]` | no |
| fluentbit_config_file | Fluentbit conf file name. Allowed values: minimize-log-loss|parse-json. | string | `parse-json` | no |
| app_image | App image url. Default is "${var.ecr_repo_url}:${var.environment}" | string | `null` | no |
| ephemeral_storage | Ephemeral storage to provision. Must be between 20 and 200 | number | `20` | no |

#### targets Properties
| Name | Description | Type |
|------|-------------|------|
| port | Target group port | number |
| protocol | Target group protocol | string |
| target_deregistration_delay | Value to set target group deregistration delay | number |
| service_paths | Conditional path for path based routing | list(string) |
| host_headers | Conditional host_headers for host based routing | list(string) |
| source_ips | Conditional list of source IP CIDR notations to match | list(string) |
| http_request_methods | Conditional list of HTTP request methods or verds to match | list(string) |
| health_check | Optional target group health check properties. See health_check properties below | map |
| load_balancer_arn | ECS service load balancer arn | string |
| load_balancer_arn_suffix | ECS service load balancer arn suffix. Required for NLBs to extract nic IPs. Ignored for ALBs. | string |
| listener_arn | Listener arn. Required for ALBs | string |
| load_balancer_security_group_id | ECS service load balancer security group id for ALBs | string |
| lb_certificate_arn | Optional ACM arn to configure NLB listener if protocol is TLS. Ignored if load balancer is an ALB. | string |
| lb_port | Optional port to configure NLB listener if protocol is TLS. Defaults to 443 for TLS. Ignored if load balancer is an ALB. | number |
| http_headers | Conditional http_headers for routing based on custom http headers | map |

#### health_check Properties
| Name | Description | Type |
|------|-------------|------|
| enabled | Whether health checks are enabled. | bool |
| healthy_threshold | Number of consecutive health checks. | number |
| interval | Approximate amount of time, in seconds, between health checks of an individual target | number |
| matcher | Response codes to use when checking for a healthy responses from a target.  | string |
| path | Destination for the health check request. | string |
| port | Port to use to connect with the target. | number |
| protocol | Protocol to use to connect with the target for health check. | number |
| timeout | Amount of time, in seconds, during which no response means a failed health check. | number |
| unhealthy_threshold | Number of consecutive health check failures required before considering the target unhealthy. | number |

## Outputs
| Name | Description |
|------|-------------|
| ecs_service_security_group_id | Id of security group in ECS service network configuration |
| ecs_target_group_arn | ECS service load balancer target group arn |
| task_definition | Task definition family:revision value |
| task_definition_arn | Task definition arn |
| lb_listener_arn | Arn of the load balancer listener associated to container target group |
| task_role_arn | Task definition task role arn |
| execution_role_arn | Task definition execution role arn |
| environment_files | List of s3 environment files associated with service container.  |
