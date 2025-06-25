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

resource "azurerm_resource_group" "system" {
  name     = "system"
  location = "eastus"
}
