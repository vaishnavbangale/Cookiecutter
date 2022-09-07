module "fargate_auto_scaling" {
  source = "./modules/fargate_auto_scaling"
  count  = var.enable_autoscaling && var.launch_type == "FARGATE" ? 1 : 0

  application_name                 = var.application_name
  environment                      = var.environment
  ecs_cluster_name                 = var.ecs_cluster_name
  ecs_service_name                 = aws_ecs_service.application_service.name
  max_capacity                     = var.max_capacity
  min_capacity                     = var.min_capacity
  ecs_alarms_cpu_low_threshold     = var.ecs_alarms_cpu_low_threshold
  ecs_alarms_cpu_high_threshold    = var.ecs_alarms_cpu_high_threshold
  ecs_alarms_memory_low_threshold  = var.ecs_alarms_memory_low_threshold
  ecs_alarms_memory_high_threshold = var.ecs_alarms_memory_high_threshold
  tags = merge(
    var.tags,
    {
      terraform-module = "module.fargate_auto_scaling"
    }
  )
}

#-----------------
# EC2 type

resource "aws_launch_configuration" "application_service" {
  count                       = var.enable_autoscaling && var.launch_type == "EC2" ? 1 : 0
  name_prefix                 = "ecs-${var.application_name}-${var.environment}-${local.region_abbrv}"
  image_id                    = data.aws_ami.application_service.id
  instance_type               = var.instance_type_spot
  enable_monitoring           = true
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
  #!/bin/bash
  echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
  EOF

  security_groups = [
    aws_security_group.ecs_service.id
  ]

  iam_instance_profile = aws_iam_instance_profile.exec[0].arn
}

resource "aws_autoscaling_group" "app_spot" {
  count                     = var.enable_autoscaling && var.launch_type == "EC2" ? 1 : 0
  name_prefix               = "${var.ecs_cluster_name}_${var.application_name}_"
  default_cooldown          = 30
  health_check_grace_period = 30
  max_size                  = var.max_capacity
  min_size                  = var.min_capacity
  desired_capacity          = var.min_capacity

  launch_configuration = aws_launch_configuration.application_service[0].name

  lifecycle {
    create_before_destroy = true
  }

  vpc_zone_identifier = var.subnet_ids

  tags = concat([
    {
      key                 = "Name"
      value               = var.ecs_cluster_name,
      propagate_at_launch = true
    },
    {
      key                 = "terraform-resource"
      value               = "aws_autoscaling_group.app_spot"
      propagate_at_launch = true
    }
    ], [
    for k, v in var.tags : {
      key                 = k
      value               = v
      propagate_at_launch = true
    }
    if k != "Name" || k != "terraform-resource"
  ])
}