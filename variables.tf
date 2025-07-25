variable "subscription" {
  description = "Azure subscription ID dedicated to Vespa Cloud Enclave"
  type        = string
}

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
