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

// Issuer (Athenz ZTS) URL for federated identity credentials.
variable "__zts_url" {
  description = "Internal, do not override."
  type        = string
  default     = "https://zts.athenz.vespa-cloud.com:4443/zts/v1"
}

// Temporary array of user principals
// TODO: Remove after deciding how to manage operator access.
variable "__operators" {
  description = "Internal, do not override."
  type        = list(string)
  default     = []
}
