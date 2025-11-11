// Controller identity and permissions for Vespa Cloud controller access

resource "azurerm_user_assigned_identity" "controller" {
  location            = local.main_region
  name                = "id-controller"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

resource "azurerm_federated_identity_credential" "controller" {
  name                = "athenz"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = local.issuer_url
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.controller.id
  subject             = "vespa.tenant.${var.tenant_name}.azure-${data.azurerm_subscription.current.subscription_id}:role.azure.controller"
}

resource "azurerm_role_definition" "controller_archive" {
  name        = "vespa-controller-archive-${data.azurerm_subscription.current.subscription_id}"
  scope       = data.azurerm_subscription.current.id
  description = "Gives controller access to the storage account"

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/read" // Read the storage account name
    ]
  }
}

resource "azurerm_role_assignment" "controller_archive" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.controller_archive.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.controller.principal_id
}

resource "azurerm_role_definition" "controller_system" {
  name        = "vespa-controller-${data.azurerm_subscription.current.subscription_id}"
  scope       = azurerm_resource_group.system.id
  description = "Gives the controller access to the system resource group"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read", // Read the resource group itself
      "Microsoft.Resources/tags/read"                          // Read the version tag
    ]
  }
}

resource "azurerm_role_assignment" "controller_system" {
  scope              = azurerm_resource_group.system.id
  role_definition_id = azurerm_role_definition.controller_system.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.controller.principal_id
}
