terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

locals {
  template_version = "0.0.1"
}

module "provision" {
  source           = "./modules/provision"
  tenant_name      = var.tenant_name
  template_version = local.template_version
}
