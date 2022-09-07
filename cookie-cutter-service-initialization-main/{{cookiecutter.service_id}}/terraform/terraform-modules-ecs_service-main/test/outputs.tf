output "ecs_service_alb_output" {
  value = module.test_ecs_service
}

output "ecs_service_nlb_output" {
  value = module.test_ecs_service_nlb
}

# output format for test
output "output_json" {
  value = jsonencode(
    {
      ecs_service_alb_output = module.test_ecs_service
      ecs_service_nlb_output = module.test_ecs_service_nlb
      app_name_1             = local.app_name_1
      app_name_2             = local.app_name_2
      cluster_name           = local.cluster_name
      cluster_id             = local.cluster_id
      id                     = var.id
      environment            = local.environment
      region_abbrv           = local.region_abbrv
      subnets = [
        data.terraform_remote_state.core.outputs.priv_us_east_1a_subnet_id,
        data.terraform_remote_state.core.outputs.priv_us_east_1b_subnet_id,
        data.terraform_remote_state.core.outputs.priv_us_east_1c_subnet_id,
      ]
      vpc_id                  = local.vpc_id
      auto_scaling_thresholds = local.auto_scaling_thresholds
    }
  )
}