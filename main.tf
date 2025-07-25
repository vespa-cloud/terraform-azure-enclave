terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
    }
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

resource "azapi_resource_action" "enable_encryption_at_host" {
  type        = "Microsoft.Resources/subscriptions@2021-07-01"
  resource_id = "/subscriptions/${var.subscription}"
  action      = "/providers/Microsoft.Features/providers/Microsoft.Compute/features/EncryptionAtHost/register"
  body        = {}
}
