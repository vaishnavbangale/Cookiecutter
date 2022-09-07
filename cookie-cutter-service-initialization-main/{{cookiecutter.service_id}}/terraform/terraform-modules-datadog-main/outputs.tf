output "monitor_id" {
  value = {
    for key, val in var.monitors : key => datadog_monitor.monitor[key].id
  }
}

output "dashboard_id" {
  value = {
    for key, val in var.dashboards : key => datadog_dashboard_json.dashboard[key].id
  }
}