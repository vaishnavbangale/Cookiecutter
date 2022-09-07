resource "datadog_monitor" "monitor" {
  for_each = var.monitors

  name    = lookup(each.value, "name", each.key)
  type    = each.value.type
  message = each.value.message
  query   = each.value.query

  enable_logs_sample = lookup(each.value, "enable_logs_sample", null)
  escalation_message = lookup(each.value, "escalation_message", null)
  evaluation_delay   = lookup(each.value, "evaluation_delay", null)

  dynamic "monitor_threshold_windows" {
    for_each = lookup(each.value, "monitor_threshold_windows", null) == null ? [] : [each.value.monitor_threshold_windows]
    content {
      recovery_window = lookup(monitor_threshold_windows.value, "recovery_window", null)
      trigger_window  = lookup(monitor_threshold_windows.value, "trigger_window", null)
    }
  }

  dynamic "monitor_thresholds" {
    for_each = lookup(each.value, "monitor_thresholds", null) == null ? [] : [each.value.monitor_thresholds]
    content {
      critical          = lookup(monitor_thresholds.value, "critical", null)
      critical_recovery = lookup(monitor_thresholds.value, "critical_recovery", null)
      ok                = lookup(monitor_thresholds.value, "ok", null)
      unknown           = lookup(monitor_thresholds.value, "unknown", null)
      warning           = lookup(monitor_thresholds.value, "warning", null)
      warning_recovery  = lookup(monitor_thresholds.value, "warning_recovery", null)
    }
  }
  groupby_simple_monitor = lookup(each.value, "groupby_simple_monitor", false)
  include_tags           = lookup(each.value, "include_tags", false)
  locked                 = lookup(each.value, "locked", false)
  new_group_delay        = lookup(each.value, "new_group_delay", null)
  no_data_timeframe      = lookup(each.value, "no_data_timeframe", null)
  notify_audit           = lookup(each.value, "notify_audit", false)
  notify_no_data         = lookup(each.value, "notify_no_data", false)
  priority               = lookup(each.value, "priority", null)
  renotify_interval      = lookup(each.value, "renotify_interval", null)
  require_full_window    = lookup(each.value, "require_full_window", null)
  tags                   = lookup(each.value, "tags", null)
  timeout_h              = lookup(each.value, "timeout_h", null)
  validate               = var.validate
}