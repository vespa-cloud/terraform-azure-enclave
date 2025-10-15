terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  main_region = "eastus"
  default_tags = {
    vespa_template_version = var.template_version
    managed_by             = "vespa_cloud"
  }
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "system" {
  name     = "system"
  location = local.main_region
  tags     = local.default_tags
}

resource "azurerm_user_assigned_identity" "identity" {
  location            = local.main_region
  name                = "id-tenant"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

resource "azurerm_user_assigned_identity" "provisioner" {
  location            = local.main_region
  name                = "id-provisioner"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

resource "azurerm_role_definition" "provisioner" {
  name        = "provisioner"
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
      "Microsoft.Compute/skus/read",
      "Microsoft.Storage/storageAccounts/read"
    ]
  }
}

resource "azurerm_role_assignment" "provisioner" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.provisioner.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.provisioner.principal_id
}

resource "azurerm_role_assignment" "provisioner_rg_reader" {
  scope                = azurerm_resource_group.system.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.provisioner.principal_id
}

resource "azurerm_user_assigned_identity" "athenz" {
  location            = local.main_region
  name                = "id-athenz"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

resource "azurerm_role_definition" "athenz" {
  name        = "athenz"
  scope       = data.azurerm_subscription.current.id
  description = "Allows athenz to retrieve id-provisioner identity"
  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.Compute/virtualMachines/read"
    ]
  }
}

resource "azurerm_role_assignment" "azure" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.athenz.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.athenz.principal_id
}

resource "azurerm_federated_identity_credential" "athenz" {
  name                = "athenz"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = var.issuer_url
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.athenz.id
  subject             = "athenz.azure:role.azure-client"
}

# Additional federated credential for Athenz using issuer on port 443 (otherwise identical)
resource "azurerm_federated_identity_credential" "athenz_443" {
  name                = "athenz-443"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = replace(var.issuer_url, ":4443", ":443")
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.athenz.id
  subject             = "athenz.azure:role.azure-client"
}

resource "azurerm_federated_identity_credential" "provisioner" {
  name                = "athenz"
  resource_group_name = azurerm_resource_group.system.name
  issuer              = var.issuer_url
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.provisioner.id
  subject             = "vespa.tenant.${var.tenant_name}.azure-${data.azurerm_subscription.current.subscription_id}:role.azure.provisioner"
}

resource "azapi_resource_action" "enable_encryption_at_host" {
  type        = "Microsoft.Resources/subscriptions@2021-07-01"
  resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  action      = "/providers/Microsoft.Features/providers/Microsoft.Compute/features/EncryptionAtHost/register"
  body        = {}
}

output "client_id" {
  value = azurerm_user_assigned_identity.athenz.client_id
}
