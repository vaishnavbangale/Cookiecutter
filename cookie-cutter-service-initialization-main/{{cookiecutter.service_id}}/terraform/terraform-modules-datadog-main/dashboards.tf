locals {
  dashboard_jsons = {
    for key, val in var.dashboards : key => jsonencode({
      title                     = lookup(val, "title", key)
      description               = lookup(val, "description", "")
      layout_type               = lookup(val, "layout_type", "ordered")
      is_read_only              = lookup(val, "is_read_only", true)
      notify_list               = lookup(val, "notify_list", [])
      reflow_type               = lookup(val, "reflow_type", "auto")
      widgets                   = val["widgets"]
      template_variables        = lookup(val, "template_variables", [])
      template_variable_presets = lookup(val, "template_variable_presets", [])
    })
  }
}

resource "datadog_dashboard_json" "dashboard" {
  for_each  = local.dashboard_jsons
  dashboard = each.value
}