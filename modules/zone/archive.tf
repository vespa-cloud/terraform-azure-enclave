
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
  public_network_access_enabled   = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
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

  # Workaround for an azurerm provider bug causing unnecessary diffs. The provider seems to think
  # that we are using a legacy inline customer_managed_key block in this storage account resource,
  # instead of the separate azurerm_storage_account_customer_managed_key resource.
  lifecycle {
    ignore_changes = [customer_managed_key]
  }
}

# Blob/storage container for the host archive
resource "azurerm_storage_container" "host_archive" {
  storage_account_id    = azurerm_storage_account.archive.id
  name                  = "hosted-vespa"
  container_access_type = "private"
}

# Blob/storage container for the node archive
resource "azurerm_storage_container" "node_archive" {
  storage_account_id    = azurerm_storage_account.archive.id
  name                  = var.__enclave_infra.tenant_name
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
resource "azurerm_role_assignment" "host_archive_blob_reader" {
  for_each             = toset(var.archive_reader_principals)
  scope                = azurerm_storage_container.host_archive.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}
resource "azurerm_role_assignment" "node_archive_blob_reader" {
  for_each             = toset(var.archive_reader_principals)
  scope                = azurerm_storage_container.node_archive.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

# Key vault setup
resource "random_string" "vault" {
  length  = 6
  special = false
  upper   = false
}
resource "azurerm_key_vault" "archive" {
  name                          = "vault-archive-${random_string.vault.result}"
  resource_group_name           = azurerm_resource_group.zone.name
  location                      = azurerm_resource_group.zone.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = true

  # Note: 'enable_rbac_authorization' is deprecated for removal in v5, so don't put it back
  rbac_authorization_enabled = true

  tags = {
    managedby = "vespa-cloud"
    zone      = var.zone.name
  }
}

# Key for archive encryption
resource "azurerm_key_vault_key" "archive" {
  # checkov:skip=CKV_AZURE_40: Expiration is managed by rotation_policy (expire_after=90d)
  name         = "vespa-archive-key-${var.zone.environment}-${var.zone.region}"
  key_vault_id = azurerm_key_vault.archive.id
  key_type     = "RSA" # AES-256 (AWS default) is not supported in azure tf
  key_size     = 4096
  key_opts     = ["unwrapKey", "wrapKey"]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
  tags = {
    zone = var.zone.name
  }
  depends_on = [azurerm_role_assignment.archive_crypto_officer]
}

# RBAC: grant key crypto officer rights
resource "azurerm_role_assignment" "archive_crypto_officer" {
  for_each             = toset(local.effective_key_officers)
  scope                = azurerm_key_vault.archive.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = each.value
}

# RBAC: allow storage account managed identity to use (wrap/unwrap) the key
resource "azurerm_role_assignment" "archive_storage_encryption_user" {
  scope                = azurerm_key_vault.archive.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.archive.identity[0].principal_id
}

# Grant blob writer permissions on storage account
resource "azurerm_role_assignment" "id_tenant_archive_writer" {
  scope              = azurerm_storage_account.archive.id
  role_definition_id = var.__enclave_infra.archive_writer_role_resource_id
  principal_id       = var.__enclave_infra.id_tenant_principal_id
}

# Attach key to storage account (CMK)
resource "azurerm_storage_account_customer_managed_key" "archive_customer_managed_key" {
  storage_account_id = azurerm_storage_account.archive.id
  key_vault_id       = azurerm_key_vault.archive.id
  key_name           = azurerm_key_vault_key.archive.name
  depends_on = [
    azurerm_role_assignment.archive_storage_encryption_user
  ]
}
