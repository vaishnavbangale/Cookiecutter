module "monitor_definitions" {
  source = "git@github.com:HappyMoneyInc/terraform-modules-datadog-catalog.git?ref=v0.1.3"

  ecs_monitor = {
    enabled         = true
    custom_monitors = null
    attributes = {
      (local.app_service.service_name) = {
        service_name = "ecs-service-${local.app_service.service_name}-green-${var.environment}-${module.lookup_map_ue1.region_abbrv}"
      }
    }
  }

  exclude_monitors = []
}

module "datadog_monitor" {
  source   = "git@github.com:HappyMoneyInc/terraform-modules-datadog.git?ref=v0.1.3"
  monitors = module.monitor_definitions.monitors
}