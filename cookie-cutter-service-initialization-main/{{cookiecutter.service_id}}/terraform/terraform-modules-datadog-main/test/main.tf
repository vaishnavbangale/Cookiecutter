terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "datadog" {
  # APP KEY from env variable DD_APP_KEY
  api_key = data.aws_ssm_parameter.dd_api_key.value
  version = "3.3.0"
}

provider "aws" {
  region  = "us-east-1"
  version = "3.57.0"
}

data "aws_ssm_parameter" "dd_api_key" {
  name = "/logging/datadog_token"
}

variable "id" {
  type = string
}

locals {
  monitor_name   = "DD module test monitor ${var.id}"
  dashboard_name = "DD module test dashboard ${var.id}"
}

module datadog_monitor {
  source = "../"
  monitors = {
    "datadog module test" = {
      name    = local.monitor_name
      type    = "log alert"
      message = "Monitor triggered. Notify: @slack-devops_test_channel"
      query   = "logs(\"cluster_name:*dev* @level:ERROR Service:devops-demo-green\").index(\"*\").rollup(\"count\").by(\"service\").last(\"5m\") > 0"
    }
  }
}

module datadog_dashboard {
  source = "../"
  dashboards = {
    "datadog module test" = {
      title       = local.dashboard_name
      description = "created by terraform"
      widgets = [
        {
          "definition" = {
            "title"         = "Health"
            "show_legend"   = true
            "legend_layout" = "auto"
            "legend_columns" = [
              "avg",
              "min",
              "max",
              "value",
              "sum"
            ]
            "type" = "timeseries",
            "requests" = [
              {
                "formulas" = [
                  {
                    "alias"   = "Errors"
                    "formula" = "query1"
                  }
                ]
                "response_format" = "timeseries"
                "queries" = [
                  {
                    "search" = {
                      "query" = "service:devops-demo-green error env:dev"
                    }
                    "data_source" = "logs"
                    "compute" = {
                      "aggregation" = "count"
                    }
                    "name"     = "query1"
                    "indexes"  = ["*"]
                    "group_by" = []
                  }
                ]
                "style" = {
                  "palette"    = "dog_classic"
                  "line_type"  = "solid"
                  "line_width" = "normal"
                }
                "display_type" = "line"
              }
            ]
            "yaxis" = {
              "include_zero" = true
              "scale"        = "linear"
              "label"        = ""
              "min"          = "auto"
              "max"          = "auto"
            },
            "markers" = []
          }
        }
      ]
    }
  }
}

output "dd_monitor_output" {
  value = module.datadog_monitor
}

output "dd_dashboard_output" {
  value = module.datadog_dashboard
}

output "output_json" {
  value = jsonencode({
    monitor_id   = module.datadog_monitor.monitor_id["datadog module test"]
    dashboard_id = module.datadog_dashboard.dashboard_id["datadog module test"]
    }
  )
}