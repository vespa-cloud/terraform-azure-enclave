// Provisioner identity and permissions for VM and load balancer provisioning

resource "azurerm_user_assigned_identity" "provisioner" {
  location            = local.main_region
  name                = "id-provisioner"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

resource "azurerm_federated_identity_credential" "provisioner" {
  name                = "athenz"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = local.issuer_url
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.provisioner.id
  subject             = "vespa.tenant.${var.tenant_name}.azure-${data.azurerm_subscription.current.subscription_id}:role.azure.provisioner"
}

resource "azurerm_role_definition" "provisioner" {
  name        = "vespa-provisioner-${data.azurerm_subscription.current.subscription_id}"
  scope       = data.azurerm_subscription.current.id
  description = "Allow config servers to provision resources"

  permissions {
    actions = [
      "Microsoft.Compute/diskEncryptionSets/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Network/loadBalancers/backendAddressPools/read",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/loadBalancers/backendAddressPools/write",
      "Microsoft.Network/virtualNetworks/joinLoadBalancer/action",
      "Microsoft.Network/loadBalancers/delete",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Compute/skus/read"
    ]
  }
}

resource "azurerm_role_assignment" "provisioner" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.provisioner.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.provisioner.principal_id
}
