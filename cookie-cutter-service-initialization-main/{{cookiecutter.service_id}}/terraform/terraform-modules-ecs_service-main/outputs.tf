output "ecs_service_security_group_id" {
  value = aws_security_group.ecs_service.id
}

output "ecs_target_group_arn" {
  description = "Map for ecs target group arns corresponding to input targets"
  value = {
    for key, val in var.targets : key => aws_lb_target_group.ecs_application_targets[key].arn
  }
}

output "task_definition" {
  value = "${aws_ecs_task_definition.application_task.family}:${aws_ecs_task_definition.application_task.revision}"
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.application_task.arn
}

output "lb_listener_arn" {
  value = {
    for key, val in var.targets : key => val["lb_type"] == "nlb" ? aws_lb_listener.container_service[key].arn : val.listener_arn
  }
}

output "fargate_auto_scaling" {
  value = var.enable_autoscaling && var.launch_type == "FARGATE" ? ({
    utilization_low_alarm = {
      alarm_name = module.fargate_auto_scaling[0].utilization_low_alarm.alarm_name
      arn        = module.fargate_auto_scaling[0].utilization_low_alarm.arn
      id         = module.fargate_auto_scaling[0].utilization_low_alarm.id
    }
    utilization_high_alarm = {
      alarm_name = module.fargate_auto_scaling[0].utilization_high_alarm.alarm_name
      arn        = module.fargate_auto_scaling[0].utilization_high_alarm.arn
      id         = module.fargate_auto_scaling[0].utilization_high_alarm.id
    }
    app_up_policy = {
      arn         = module.fargate_auto_scaling[0].app_up_policy.arn
      name        = module.fargate_auto_scaling[0].app_up_policy.name
      policy_type = module.fargate_auto_scaling[0].app_up_policy.policy_type
    }
    app_down_policy = {
      arn         = module.fargate_auto_scaling[0].app_down_policy.arn
      name        = module.fargate_auto_scaling[0].app_down_policy.name
      policy_type = module.fargate_auto_scaling[0].app_down_policy.policy_type
    }
  }) : null
}

output "ecs_service_name" {
  value = aws_ecs_service.application_service.name
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}

output "execution_role_arn" {
  value = aws_iam_role.exec.arn
}

output "environment_files" {
  value = [
    for path in var.environmentfile_bucket_paths : "${path.arn}/${path.key_name}"
  ]
}