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

resource "azurerm_role_assignment" "id_operator" {
  for_each = toset([
    "Virtual Machine Administrator Login",
    "Reader",
  ])
  scope                = data.azurerm_subscription.current.id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.id_operator.principal_id
}
