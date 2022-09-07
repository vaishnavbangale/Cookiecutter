variable "monitors" {
  description = "Map of DataDog Monitors (resource alarms) to create."
  default     = {}
}

variable "dashboards" {
  description = "Map of DataDog Dashboards, including widgets, to create."
  default     = {}
}

variable "validate" {
  type        = bool
  description = "Enable validate on datadog resources. Requires DD App key in provider"
  default     = true
}

variable "datadog_api_key" {
  type = string
}

variable "datadog_app_key" {
  type = string
}