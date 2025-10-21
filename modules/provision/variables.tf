variable "tenant_name" {
  description = "The tenant owner running enclave account"
  type        = string
}

// Version string of this template in MAJOR.MINOR.PATCH format.
variable "template_version" {
  description = "Internal, do not override."
  type        = string
  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.template_version))
    error_message = "Enclave template version expected to be in MAJOR.MINOR.PATCH format."
  }
}

// See variables.tf in root module
variable "all_zones" {
  description = "Internal, do not override."
  type = list(object({
    environment   = string
    physical_zone = string
  }))
  default = [
    { environment = "dev", physical_zone = "eastus-az1" },
  ]
}

// See variables.tf in root module
variable "issuer_url" {
  description = "Internal, do not override."
  type        = string
  default     = "https://zts.athenz.vespa-cloud.com:4443/zts/v1"
}
