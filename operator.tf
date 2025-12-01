// Operator identity and permissions for SSH access to VMs

resource "azurerm_user_assigned_identity" "id_operator" {
  name                = "id-operator"
  location            = azurerm_resource_group.system.location
  resource_group_name = azurerm_resource_group.system.name
}

resource "azurerm_federated_identity_credential" "id_operator" {
  for_each            = toset(var.__operators)
  name                = "operator-${each.value}"
  parent_id           = azurerm_user_assigned_identity.id_operator.id
  resource_group_name = azurerm_resource_group.system.name
  issuer              = local.issuer_url
  audience            = ["${local.athenz_domain}:${local.athenz_operator_role}"]
  subject             = "user.${each.value}"
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

  assignable_scopes = [
    data.azurerm_subscription.current.id,
  ]
}
