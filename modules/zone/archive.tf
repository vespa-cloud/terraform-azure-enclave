resource "random_string" "archive" {
  length  = 6
  special = false
  upper   = false
}

# Random ID name with prefix (standard also for noclave)
locals {
  storage_name = "vespaarchive${random_string.archive.id}"
}

# Storage account (top level wrapper around containers)
resource "azurerm_storage_account" "archive" {
  name                            = local.storage_name
  resource_group_name             = azurerm_resource_group.zone.name
  location                        = azurerm_resource_group.zone.location
  account_tier                    = "Standard"
  access_tier                     = "Hot"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = false
  }

  # System-assigned identity to provide key vault access
  identity {
    type = "SystemAssigned"
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
  scope                = azurerm_storage_container.archive.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

# Key vault setup
resource "azurerm_key_vault" "archive" {
  name                       = "vault-archive"
  resource_group_name        = azurerm_resource_group.zone.name
  location                   = azurerm_resource_group.zone.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  tags = {
    managedby = "vespa-cloud"
    zone      = var.zone.name
  }
}

# Key for archive encryption
resource "azurerm_key_vault_key" "archive" {
  name         = "vespa-archive-key-${var.zone.environment}-${var.zone.region}"
  key_vault_id = azurerm_key_vault.archive.id
  key_type     = "RSA" # AES-256 (AWS default) is not supported in azure tf
  key_size     = 4096
  key_opts     = ["unwrapKey", "wrapKey"]

  rotation_policy {
    # Expire after two years, notify 30 days before expiry
    expire_after         = "P2Y"
    notify_before_expiry = "P30D"
    # Automatic rotation after 1 year
    automatic {
      time_after_creation = "P1Y"
    }
  }

  depends_on = [azurerm_key_vault_access_policy.caller]
}

# Grant caller identity permissions on key
resource "azurerm_key_vault_access_policy" "caller" {
  key_vault_id = azurerm_key_vault.archive.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  key_permissions = [
    "Get", "List", "Create", "Update", "Delete",
    "GetRotationPolicy", "SetRotationPolicy"
  ]
}

# Grant storage account permissions on key
resource "azurerm_key_vault_access_policy" "sa" {
  key_vault_id    = azurerm_key_vault.archive.id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  object_id       = azurerm_storage_account.archive.identity[0].principal_id
  key_permissions = ["Get", "UnwrapKey", "WrapKey"]
}

# Attach key to storage account
resource "azurerm_storage_account_customer_managed_key" "example" {
  storage_account_id = azurerm_storage_account.archive.id
  key_vault_id       = azurerm_key_vault.archive.id
  key_name           = azurerm_key_vault_key.archive.name
  depends_on = [
    azurerm_key_vault_access_policy.sa
  ]
}
