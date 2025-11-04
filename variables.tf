variable "tenant_name" {
  description = "The Vespa Cloud tenant name that will operate in this subscription."
  type        = string
}

// List of Azure Vespa Cloud zones. Overriding is only for Vespa internal tests.
// New zones must be added to the default value here.
variable "__all_zones" {
  description = "Internal, do not override."
  type = list(object({
    environment   = string
    physical_zone = string
  }))
  default = [
    { environment = "dev", physical_zone = "eastus-az1" },
  ]
}

// Issuer (Athenz ZTS) URL for federated identity credentials (either 'prod' or 'cd').
variable "__athenz_env" {
  description = "Internal, do not override."
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["prod", "cd"], var.__athenz_env)
    error_message = "athenz_env must be either 'prod' or 'cd'"
  }
}

// Temporary array of user principals
// TODO: Remove after deciding how to manage operator access.
variable "__operators" {
  description = "Internal, do not override."
  type        = list(string)
  default     = []
}
