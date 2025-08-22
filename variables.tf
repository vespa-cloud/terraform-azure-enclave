variable "subscription" {
  description = "Azure subscription ID dedicated to Vespa Cloud Enclave"
  type        = string
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
