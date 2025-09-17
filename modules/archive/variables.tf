
variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    name          = string, // The Vespa Cloud zone name, e.g. prod.azure-eastus-az1
    short_name    = string, // The Vespa Cloud short name used in e.g. hostnames, e.g. prod.eastus-az1
    environment   = string, // The Vespa Cloud environment, e.g. prod
    region        = string, // The Vespa Cloud region, e.g. azure-eastus-az1
    azure_region  = string, // The Azure region, e.g. eastus
    physical_zone = string, // The physical (availability) zone, e.g. eastus-az1
  })
}

variable "resource_group_name" {
  description = "Name of resource group to use for archive resources"
  type        = string
}

variable "archive_reader_principals" {
  description = "List of principal ids granted read access to the archive blob storage"
  type        = list(string)
  default     = []
}
