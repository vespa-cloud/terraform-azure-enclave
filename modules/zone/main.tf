terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

resource "azurerm_resource_group" "zone" {
  name     = var.zone.short_name
  location = var.zone.azure_region
  tags = {
    zone = var.zone.name
    type = "zone"
  }
}

