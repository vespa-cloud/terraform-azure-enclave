
variable "zone" {
  description = "Vespa Cloud zone to bootstrap"
  type = object({
    environment = string,
    region      = string,
    name        = string,
    tag         = string,
    az          = string,
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
