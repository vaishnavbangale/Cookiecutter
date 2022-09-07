variable "tags" {
  type        = map(string)
  description = "Common tags for all resources."
}

variable "vpc_id" {
  type        = string
  description = "The target VPC id."
}

variable "cloudmap_namespace" {
  type        = string
  description = "Value of the cloudmap service discovery namespace"
}

variable "cloudmap_namespace_description" {
  type        = string
  description = "Description of cloudmap service discovery namespace"
  default     = null
}

variable "cloudmap_tls_cert_enabled" {
  description = "Flag to enable creating ACM managed ACM-PCA for the cloudmap namespace"
  default     = false
}

variable "mesh_name" {
  type        = string
  description = "The name to use for the service mesh"
}

variable "mesh_egress_filter" {
  type        = string
  description = "App mesh egress filter type"
  default     = "DROP_ALL"
}

variable "region_abbrv" {
  type        = string
  description = "Region abbreviation. e.g ue1"
  default     = "ue1"
}

variable "use_assume_role" {
  type        = bool
  description = "Use assume provider role before running aws cli to set acmpca permission if using provider with assume_role since local-exec does not inherit provider"
  default     = false
}

variable "acmpca_validity_type" {
  type    = string
  default = "YEARS"
}

variable "acmpca_validity_value" {
  type    = number
  default = 20
}