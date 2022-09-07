variable "application_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "max_capacity" {
  type        = number
  description = "maximum number of containers for autoscaling"
  default     = 3
}

variable "min_capacity" {
  type        = number
  description = "minimum number of containers for autoscaling"
  default     = 1
}

variable "ecs_alarms_cpu_low_threshold" {
  type = number
}

variable "ecs_alarms_cpu_high_threshold" {
  type = number
}

variable "ecs_alarms_memory_low_threshold" {
  type = number
}

variable "ecs_alarms_memory_high_threshold" {
  type = number
}

variable "scale_up_cooldown" {
  type    = number
  default = 60
}

variable "scale_down_cooldown" {
  type    = number
  default = 300
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources."
  default     = {}
}

#-----------------------------------------------------------------------------------------

resource "aws_appautoscaling_target" "app_scale_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_cloudwatch_metric_alarm" "utilization_low" {
  alarm_name          = "${var.application_name}-${var.environment}-Utilization-Low"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1

  metric_query {
    id          = "e1"
    expression  = "IF(cpu < ${var.ecs_alarms_cpu_low_threshold} AND memory < ${var.ecs_alarms_memory_low_threshold}, 1, 0)"
    label       = "CPU and Memory Utilization low"
    return_data = "true"
  }

  metric_query {
    id          = "cpu"
    return_data = "false"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 60
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  metric_query {
    id          = "memory"
    return_data = "false"
    metric {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      period      = 60
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  alarm_actions = [aws_appautoscaling_policy.app_down.arn]

  tags = merge(
    var.tags,
    {
      Name               = "${var.application_name}-${var.environment}-Utilization-Low"
      terraform-resource = "aws_cloudwatch_metric_alarm.utilization_low"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "utilization_high" {
  alarm_name          = "${var.application_name}-${var.environment}-Utilization-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1

  metric_query {
    id          = "e1"
    expression  = "IF(cpu >= ${var.ecs_alarms_cpu_high_threshold}, 1, 0) OR IF(memory >= ${var.ecs_alarms_memory_high_threshold}, 1, 0)"
    label       = "CPU or Memory Utilization high"
    return_data = "true"
  }

  metric_query {
    id          = "cpu"
    return_data = "false"
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/ECS"
      period      = 60
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  metric_query {
    id          = "memory"
    return_data = "false"
    metric {
      metric_name = "MemoryUtilization"
      namespace   = "AWS/ECS"
      period      = 60
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  alarm_actions = [aws_appautoscaling_policy.app_up.arn]

  tags = merge(
    var.tags,
    {
      Name               = "${var.application_name}-${var.environment}-Utilization-High"
      terraform-resource = "aws_cloudwatch_metric_alarm.utilization_High"
    }
  )
}

# Auto scaling policies
resource "aws_appautoscaling_policy" "app_up" {
  name               = "app-scale-up"
  service_namespace  = aws_appautoscaling_target.app_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.app_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.app_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_up_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "app_down" {
  name               = "app-scale-down"
  service_namespace  = aws_appautoscaling_target.app_scale_target.service_namespace
  resource_id        = aws_appautoscaling_target.app_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.app_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_down_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

output "utilization_low_alarm" {
  value = aws_cloudwatch_metric_alarm.utilization_low
}

output "utilization_high_alarm" {
  value = aws_cloudwatch_metric_alarm.utilization_high
}

output "app_up_policy" {
  value = aws_appautoscaling_policy.app_up
}

output "app_down_policy" {
  value = aws_appautoscaling_policy.app_down
}