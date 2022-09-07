variable "cloudmap_namespace" {
  type        = string
  description = "Value of the cloudmap service discovery namespace"
}

variable "cloudmap_namespace_type" {
  type        = string
  description = "Value of the cloudmap service discovery namespace type"
  default     = "DNS_PRIVATE"
}

variable "app_mesh_id" {
  type        = string
  description = "App mesh ID."
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources."
}

variable "name" {
  type        = string
  description = "Name of the service"
}

variable "description" {
  type        = string
  description = "Description for the service"
  default     = null
}

variable "dns_records" {
  description = "List of DNS records to create for the backend cloudmap service"
  default = [
    {
      ttl  = 60
      type = "A"
    },
    {
      ttl  = 60
      type = "SRV"
    }
  ]
}

variable "routing_policy" {
  type        = string
  description = "The routing policy that you want to apply to all records that Route 53 creates when you register an instance and specify the service. Valid Values: MULTIVALUE, WEIGHTED"
  default     = null
}

variable "health_check_custom_config" {
  type        = map(any)
  description = "Settings for ECS managed health checks"
  default     = null
}

variable "health_check_config" {
  type        = map(any)
  description = "Settings for an optional health check. Only for Public DNS namespaces."
  default     = null
}

variable "router_port_mapping" {
  description = "Map that defines port and protocol of virtual router listener."
}

variable "nodes" {
  description = "Map of virtual node configurations part of the virtual service."
  default     = {}
}

variable "routes" {
  description = "List of service routes with weighted targets objects"
  default     = []
}

variable "virtual_gateway_route" {
  type        = map(string)
  description = "Optional map with virtual_gateway_name and match_prefix for creating a virtual gateway route to the service"
  default     = null
}

variable "http_service_route_retry_enabled" {
  type        = bool
  description = "If true, enables service route retry for http route"
  default     = true
}

variable "vpc_id" {
  type         = string
  description  = ""
  default      = null
}