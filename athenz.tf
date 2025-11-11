// Athenz authentication service identity and permissions

resource "azurerm_user_assigned_identity" "athenz" {
  location            = local.main_region
  name                = "id-athenz"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

resource "azurerm_federated_identity_credential" "athenz" {
  name                = "athenz"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = local.issuer_url
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.athenz.id
  subject             = "athenz.azure:role.azure-client"
}

# Additional federated credential for Athenz using issuer on port 443 (otherwise identical)
resource "azurerm_federated_identity_credential" "athenz_443" {
  name                = "athenz-443"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = replace(local.issuer_url, ":4443", ":443")
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.athenz.id
  subject             = "athenz.azure:role.azure-client"
}

resource "azurerm_role_definition" "athenz" {
  name        = "vespa-athenz-${data.azurerm_subscription.current.subscription_id}"
  scope       = data.azurerm_subscription.current.id
  description = "Gives Athenz access to the subscription"
  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/read", // Lookup client ID of user-assigned managed identities
      "Microsoft.Compute/virtualMachines/read"
    ]
  }
}

resource "azurerm_role_assignment" "azure" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.athenz.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.athenz.principal_id
}
