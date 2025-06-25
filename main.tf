terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    random = {
      source  = "hashicorp/random"
    }
  }
}

locals {
  main_region = "eastus"
}

resource "azurerm_resource_group" "system" {
  name     = "system"
  location = local.main_region
}

resource "azurerm_user_assigned_identity" "identity" {
  location            = local.main_region
  name                = "id-tenant"
  resource_group_name = azurerm_resource_group.system.name
}
