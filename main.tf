terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_resource_group" "system" {
  name     = "system"
  location = "eastus"
}
