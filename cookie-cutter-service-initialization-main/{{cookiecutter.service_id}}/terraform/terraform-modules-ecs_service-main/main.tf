resource "aws_ecs_service" "application_service" {
  name                 = "ecs-service-${var.application_name}-${var.environment}-${local.region_abbrv}"
  cluster              = var.ecs_cluster_id
  task_definition      = "arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${aws_ecs_task_definition.application_task.family}:${max(aws_ecs_task_definition.application_task.revision, data.aws_ecs_task_definition.task.revision)}"
  desired_count        = var.desired_count
  force_new_deployment = true
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/platform-linux-fargate.html
  platform_version                   = var.launch_type == "EC2" ? null : "1.4.0"
  launch_type                        = var.capacity_provider_strategies == [] ? var.launch_type : null
  deployment_maximum_percent         = var.deploy_max_percent
  deployment_minimum_healthy_percent = var.deploy_min_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  propagate_tags                     = var.propagate_tags
  enable_execute_command             = var.enable_execute_command

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategies

    content {
      capacity_provider = lookup(capacity_provider_strategy.value, "capacity_provider", null)
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = compact(concat(var.security_group_ids, [aws_security_group.ecs_service.id]))
  }

  dynamic "load_balancer" {
    for_each = var.targets
    content {
      target_group_arn = aws_lb_target_group.ecs_application_targets[load_balancer.key].arn
      container_name   = var.application_name
      container_port   = load_balancer.value.port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries

    content {
      registry_arn   = service_registries.value.registry_arn
      container_name = lookup(service_registries.value, "record_type", "A") == "SRV" ? null : var.application_name
      port           = lookup(service_registries.value, "record_type", "A") == "SRV" ? service_registries.value.port : null
    }
  }

  dynamic "placement_constraints" {
    for_each = { for idx, constraint in var.constraint_type : constraint => idx }

    content {
      type = placement_constraints.key
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.deployment_circuit_breaker == null ? [] : [var.deployment_circuit_breaker]
    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    var.tags,
    {
      Name               = "ecs-service-${var.application_name}-${var.environment}-${local.region_abbrv}"
      terraform-resource = "aws_ecs_service.application_service"
    },
  )

  depends_on = [
    aws_iam_role.task,
    aws_iam_role.exec
  ]
}

data "aws_ecs_task_definition" "task" {
  # Task definition dependency workaround using revision reference
  task_definition = aws_ecs_task_definition.application_task.revision > 0 ? aws_ecs_task_definition.application_task.family : aws_ecs_task_definition.application_task.family
}

resource "aws_security_group" "ecs_service" {
  name   = "ecs-sg-${var.application_name}-${var.environment}-${local.region_abbrv}"
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name               = "ecs-sg-${var.application_name}-${var.environment}-${local.region_abbrv}"
      terraform-resource = "aws_security_group.ecs_service"
    }
  )
}

resource "aws_security_group_rule" "service_port" {
  for_each                 = merge(local.unfiltered_hc_ports_map, var.targets) # Workaround terraform apply issue
  security_group_id        = aws_security_group.ecs_service.id
  type                     = "ingress"
  from_port                = each.value["port"]
  to_port                  = each.value["port"]
  protocol                 = "tcp"
  source_security_group_id = var.targets[each.key]["lb_type"] == "alb" ? var.targets[each.key]["load_balancer_security_group_id"] : null
  cidr_blocks              = var.targets[each.key]["lb_type"] == "nlb" ? module.nlb_private_subnet_cidr[each.key].private_ip_cidrs : null
}

resource "aws_security_group_rule" "internal_network_access" {
  for_each          = { for port in local.service_ports : tostring(port) => port }
  security_group_id = aws_security_group.ecs_service.id
  type              = "ingress"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  cidr_blocks       = var.network_access_cidrs
}

resource "aws_security_group_rule" "tcp_service_discovery_ports" {
  count             = length(var.service_registries)
  security_group_id = aws_security_group.ecs_service.id
  type              = "ingress"
  from_port         = var.service_registries[count.index].port
  to_port           = var.service_registries[count.index].port
  protocol          = "tcp"
  cidr_blocks       = var.private_access_cidrs
}

resource "aws_security_group_rule" "udp_service_discovery_ports" {
  count             = length(var.service_registries)
  security_group_id = aws_security_group.ecs_service.id
  type              = "ingress"
  from_port         = var.service_registries[count.index].port
  to_port           = var.service_registries[count.index].port
  protocol          = "udp"
  cidr_blocks       = var.private_access_cidrs
}

resource "aws_security_group_rule" "ecs_service_egress" {
  security_group_id = aws_security_group.ecs_service.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/636#issuecomment-397581357
resource "random_uuid" "tg" {
  for_each = var.targets
  keepers = {
    name        = var.short_application_name == "" ? var.application_name : var.short_application_name
    protocol    = lookup(each.value, "protocol", local.default_protocol[each.value["lb_type"]])
    port        = each.value.port
    vpc_id      = var.vpc_id
    target_type = "ip"
  }
}

locals {
  #----------------------------------------------------------------
  # Target group name
  tg_name = var.short_application_name == "" ? substr(trimspace(var.application_name), 0, 14) : substr(trimspace(var.short_application_name), 0, 14)
}

resource "aws_lb_target_group" "ecs_application_targets" {
  for_each = var.targets

  name                 = substr(format("%s-%s", "lb-tg-${local.tg_name}-${each.value["port"]}", replace(random_uuid.tg[each.key].result, "-", "")), 0, 32)
  port                 = each.value["port"]
  protocol             = lookup(each.value, "protocol", local.default_protocol[each.value["lb_type"]])
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = lookup(each.value, "target_deregistration_delay", null)

  dynamic "stickiness" {
    for_each = each.value["lb_type"] == "nlb" ? [] : ["lb_cookie"]
    content {
      enabled = true
      type    = stickiness.value
    }
  }

  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", {}) == {} ? [] : [each.value["health_check"]]
    content {
      enabled             = lookup(health_check.value, "enabled", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", "traffic-port")
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
      interval            = lookup(health_check.value, "interval", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name               = substr(format("%s-%s", "lb-tg-${local.tg_name}-${each.value["port"]}", replace(random_uuid.tg[each.key].result, "-", "")), 0, 32)
      terraform-resource = "aws_lb_target_group.ecs_application_targets"
    }
  )
}

resource "aws_lb_listener_rule" "static" {
  for_each     = local.alb_targets
  listener_arn = each.value.listener_arn
  priority     = lookup(each.value, "priority", null)

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_application_targets[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value["service_paths"]
    }
  }

  condition {
    host_header {
      values = each.value["host_headers"]
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "source_ips", null) == null ? [] : [each.value["source_ips"]]

    content {
      source_ip {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "http_request_methods", null) == null ? [] : [each.value["http_request_methods"]]

    content {
      source_ip {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "http_headers", null) == null ? [] : [each.value["http_headers"]]

    content {
      http_header {
        http_header_name = condition.value.header_name
        values           = condition.value.values
      }
    }
  }

  tags = merge(
    var.tags,
    {
      terraform-resource = "aws_lb_listener_rule.static"
    }
  )
}

# NLB listeners
resource "aws_lb_listener" "container_service" {
  for_each = local.nlb_targets

  load_balancer_arn = each.value.load_balancer_arn
  port              = each.value["protocol"] == "TLS" ? lookup(each.value, "lb_port", 443) : each.value["port"]
  protocol          = lookup(each.value, "protocol", local.default_protocol[each.value["lb_type"]])

  certificate_arn = each.value["protocol"] == "TLS" ? each.value.lb_certificate_arn : null
  ssl_policy      = each.value["protocol"] == "TLS" ? "ELBSecurityPolicy-2016-08" : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_application_targets[each.key].arn
  }
  tags = merge(
    var.tags,
    {
      terraform-resource = "aws_lb_listener.container_service"
    }
  )
}
