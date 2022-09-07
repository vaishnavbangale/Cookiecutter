# terraform-modules-datadog
This creates DataDog resources for monitoring
- Monitors (Alerts)
- Dashboard

# usage #
```hcl
module datadog_monitor {
  source = "git@github.com:HappyMoneyInc/terraform-modules-datadog.git?ref=v1.0.0"
  monitors = {
    "datadog module test" = {
      name    = "datadog module name"
      type    = "log alert"
      message = "Monitor triggered. Notify: @slack-devops_test_channel"
      query   = "logs(\"cluster_name:*uat* @level:ERROR Service:test-service\").index(\"*\").rollup(\"count\").by(\"service\").last(\"5m\") > 0"
    }
  }
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| monitors | Map of DataDog Monitors (resource alarms) to create. | map | `{}` | no |
| dashboards | Map of DataDog Dashboards, including widgets, to create. | map | `{}` | no |
| validate | Enable validate on datadog resources. Requires DD App key in provider | bool | `true` | no |

## Outputs
| Name | Description |
|------|-------------|
| monitor_id | Map of monitor ids created |