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

# Add the archive module for this zone
module "archive" {
  source                    = "github.com/vespa-cloud/terraform-azure-enclave//modules/archive"
  version                   = ">= 1.0.0, < 2.0.0"
  zone                      = var.zone
  resource_group_name       = azurerm_resource_group.zone.name
  archive_reader_principals = []
}
