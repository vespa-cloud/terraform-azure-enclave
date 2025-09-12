
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "random_string" "archive" {
  length  = 6
  special = false
  upper   = false
}

# Pseudo-random 24-char name ("vespaarchive" + first 6 of subscription + 6 random = 24)
# Should we use standard noclave setup with 6 random chars only?
locals {
  sub_compact6 = substr(replace(lower(data.azurerm_client_config.current.subscription_id), "-", ""), 0, 6)
  storage_name = "vespaarchive${local.sub_compact6}${random_string.archive.id}"
}

# Storage account (top level wrapper around containers)
resource "azurerm_storage_account" "archive" {
  name                            = local.storage_name
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  access_tier                     = "Hot"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = false
  }

  tags = {
    managedby = "vespa-cloud"
    zone      = var.zone.name
  }
}

# Container (bucket equivalent)
resource "azurerm_storage_container" "archive" {
  storage_account_id    = azurerm_storage_account.archive.id
  name                  = "archive"
  container_access_type = "private"
}

# Lifecycle - expiration after 31 days
resource "azurerm_storage_management_policy" "archive" {
  storage_account_id = azurerm_storage_account.archive.id

  rule {
    name    = "expiration-rule"
    enabled = true
    filters { blob_types = ["blockBlob"] }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 31
      }
    }
  }
}

# Blob reader principals
resource "azurerm_role_assignment" "archive_blob_reader" {
  for_each             = toset(var.archive_reader_principals)
  scope                = azurerm_storage_container.archive.resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
