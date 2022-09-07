variable "alb_monitor" {
  description = "Map object inputs to generate monitor map for ALB"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "apigateway_monitor" {
  description = "Map object inputs to generate monitor map for Api Gateway"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "apigatewayv2_monitor" {
  description = "Map object inputs to generate monitor map for Api Gateway V2"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "cloudfront_monitor" {
  description = "Map object inputs to generate monitor map for Cloudfront distributions"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "docdb_monitor" {
  description = "Map object inputs to generate monitor map for Document DB"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "dynamodb_monitor" {
  description = "Map object inputs to generate monitor map for Dynamodb"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "ecs_monitor" {
  description = "Map object inputs to generate monitor map for ECS"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "lambda_monitor" {
  description = "Map object inputs to generate monitor map for lambda function"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "nlb_monitor" {
  description = "Map object inputs to generate monitor map for NLB"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "rds_monitor" {
  description = "Map object inputs to generate monitor map for RDS"
  default = {
    enabled         = false
    custom_monitors = null
  }
}

variable "notification_targets" {
  type    = string
  default = ""
}

variable "exclude_monitors" {
  type        = list(string)
  description = "List of monitor key names that will be excluded from creation. Can be used to disable defaults defined."
  default     = []
}

variable "datadog_api_key" {
  type = string
}

variable "datadog_app_key" {
  type = string
}