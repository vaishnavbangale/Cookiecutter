module "monitor_definitions" {
  source = "../../terraform-modules-datadog-catalog-main"

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
  source   = "../../terraform-modules-datadog-main"
  monitors = module.monitor_definitions.monitors
}