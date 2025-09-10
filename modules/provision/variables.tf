variable "tenant_name" {
  description = "The tenant owner running enclave account"
  type        = string
}

variable "template_version" {
  type = string
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.template_version))
    error_message = "Enclave template version expected to be in MAJOR.MINOR.PATCH format."
  }
}

// This variable is used by Vespa.ai internally for testing and development purposes.
variable "all_zones" {
  description = "All Azure Vespa Cloud zones"
  type = list(object({
    environment   = string
    physical_zone = string
  }))
  default = [
    { environment = "dev", physical_zone = "eastus-az1" },
  ]
}
