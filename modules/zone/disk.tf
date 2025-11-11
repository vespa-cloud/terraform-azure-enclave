locals {
  effective_key_officers = concat(var.key_officers, [data.azurerm_client_config.current.object_id])
}

resource "random_string" "disk" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_key_vault" "disk" {
  #checkov:skip=CKV_AZURE_109: Key must be externally available to be managed by TF, developers have no fixed IP address, TODO: consider setting when managed by Atlantis?
  #checkov:skip=CKV_AZURE_189: Same as above
  #checkov:skip=CKV2_AZURE_32: TODO: Check if this is needed; Key only used by Azure to provision instances, how would Azure access the key via a private endpoint?
  name                        = "disk-encryption-${random_string.disk.result}"
  location                    = azurerm_resource_group.zone.location
  resource_group_name         = azurerm_resource_group.zone.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  rbac_authorization_enabled  = true
  tags = {
    zone = var.zone.name
  }
}

resource "azurerm_key_vault_key" "disk" {
  #checkov:skip=CKV_AZURE_40: No expiration, auto rotation is enabled
  name         = "disk-encryption-hsm"
  key_vault_id = azurerm_key_vault.disk.id
  key_type     = "RSA-HSM"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
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
  depends_on = [azurerm_role_assignment.disk_officer]
}
resource "azurerm_disk_encryption_set" "disk" {
  name                      = "disk-encryption"
  resource_group_name       = azurerm_resource_group.zone.name
  location                  = azurerm_resource_group.zone.location
  key_vault_key_id          = azurerm_key_vault_key.disk.versionless_id
  auto_key_rotation_enabled = true

  identity {
    type = "SystemAssigned"
  }
  tags = {
    zone = var.zone.name
  }
}
resource "azurerm_role_assignment" "disk_officer" {
  for_each             = toset(local.effective_key_officers)
  scope                = azurerm_key_vault.disk.id
  role_definition_name = "Key Vault Crypto Officer" # Or "Key Vault Administrator"
  principal_id         = each.value
}
resource "azurerm_role_assignment" "disk" {
  scope                = azurerm_key_vault.disk.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.disk.identity.0.principal_id
}
