variable "tenant_name" {
  description = "The Vespa Cloud tenant name that will operate in this subscription."
  type        = string
}

// This variable is used by Vespa.ai internally for testing and development purposes.
variable "__all_zones" {
  description = "Internal: Default list of Azure Vespa Cloud zones. Do not override."
  type = list(object({
    environment   = string
    physical_zone = string
  }))
  default = [
    { environment = "dev", physical_zone = "eastus-az1" },
  ]
}

variable "__athenz_env" {
  description = "Internal: Selects the Athenz ZTS issuer URL (one of: \"prod\", \"cd\"). Do not override."
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["prod", "cd"], var.__athenz_env)
    error_message = "athenz_env must be either 'prod' or 'cd'"
  }
}
