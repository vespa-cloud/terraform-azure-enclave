// Operator identity and permissions for SSH access to VMs

resource "azurerm_user_assigned_identity" "id_operator" {
  name                = "id-operator"
  location            = azurerm_resource_group.system.location
  resource_group_name = azurerm_resource_group.system.name
}

// Single federated credential for the vespa-operator Athenz service identity.
// Operators obtain a JWT SVID for this service via the Athenz RBAC provider,
// which checks membership in the azure.ssh-login role at token request time.
resource "azurerm_federated_identity_credential" "operator_service" {
  name                = "operator-service"
  parent_id           = azurerm_user_assigned_identity.id_operator.id
  resource_group_name = azurerm_resource_group.system.name
  issuer              = local.issuer_url
  audience            = ["${local.athenz_domain}:${local.athenz_operator_role}"]
  subject             = "${local.athenz_domain}.vespa-operator"
}

// Deprecated: Per-user federated credentials. Use vespa-operator service identity instead.
resource "azurerm_federated_identity_credential" "id_operator" {
  for_each            = toset(var.__operators)
  name                = "operator-${each.value}"
  parent_id           = azurerm_user_assigned_identity.id_operator.id
  resource_group_name = azurerm_resource_group.system.name
  issuer              = local.issuer_url
  audience            = ["${local.athenz_domain}:${local.athenz_operator_role}"]
  subject             = "user.${each.value}"
}

// Expose the id-operator client ID as a tag on the system resource group.
// Uses azapi_update_resource to avoid a circular dependency (id_operator depends on system RG).
resource "azapi_update_resource" "system_operator_tag" {
  type        = "Microsoft.Resources/resourceGroups@2024-03-01"
  resource_id = azurerm_resource_group.system.id
  body = {
    tags = {
      vespa_operator_client_id = azurerm_user_assigned_identity.id_operator.client_id
    }
  }
}

resource "azurerm_role_definition" "bastion_vm_connect_reader" {
  name        = "vespa-operator-${data.azurerm_subscription.current.subscription_id}"
  scope       = data.azurerm_subscription.current.id
  description = "Allows id-operator to read bastion hosts if SSH is enabled"

  permissions {
    actions = [
      "Microsoft.Network/bastionHosts/read"
    ]
  }
}
