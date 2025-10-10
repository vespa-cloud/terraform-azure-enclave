variable "tenant_name" {
  description = "The tenant owner running enclave account"
  type        = string
}

// This variable is used by Vespa.ai internally for testing and development purposes.
variable "__all_zones" {
  description = "All Azure Vespa Cloud zones"
  type = list(object({
    environment   = string
    physical_zone = string
  }))
  default = [
    { environment = "dev", physical_zone = "eastus-az1" },
  ]
}

variable "__athenz_env" {
  description = "Athenz environment selector for ZTS issuer URL. One of: 'prod', 'cd'."
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["prod", "cd"], var.__athenz_env)
    error_message = "athenz_env must be either 'prod' or 'cd'"
  }
}
