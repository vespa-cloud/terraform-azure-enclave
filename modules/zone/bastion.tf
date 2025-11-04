
locals {
  bastion_subnet_name = "AzureBastionSubnet"
}

resource "azurerm_public_ip" "bastion" {
  count               = var.enable_ssh ? 1 : 0
  name                = "pip-bastion"
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_ssh ? 1 : 0
  name                = "bastion"
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name
  sku                 = "Standard"
  tunneling_enabled   = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_virtual_network.zone.id}/subnets/${local.bastion_subnet_name}"
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

// Enable flow logs for bastion NSG
resource "azurerm_network_watcher_flow_log" "bastion" {
  count                = var.enable_ssh ? 1 : 0
  name                 = "flowlogs-${var.zone.name}-bastion"
  network_watcher_name = data.azurerm_network_watcher.this.name
  resource_group_name  = data.azurerm_network_watcher.this.resource_group_name
  target_resource_id   = azurerm_network_security_group.bastion.id
  storage_account_id   = azurerm_storage_account.flow_logs_storage.id
  enabled              = true

  retention_policy {
    enabled = true
    days    = 30
  }
}

resource "azurerm_network_security_group" "bastion" {
  // This resource must be created since it is referenced by the subnet inlined in the virtual network
  // count = var.enable_ssh ? 1 : 0
  name                = "nsg-bastion"
  resource_group_name = azurerm_resource_group.zone.name
  location            = azurerm_resource_group.zone.location

  // Rules originally from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg

  // Inbound rules
  security_rule {
    priority                   = 100
    name                       = "in-https"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    priority                   = 110
    name                       = "in-gateway-manager"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "GatewayManager"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  security_rule {
    priority                   = 120
    name                       = "in-bastion-data-plane"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["8080", "5701"]
  }

  security_rule {
    priority                   = 130
    name                       = "in-loadbalancer"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "AzureLoadBalancer"
    source_port_range          = "*"
    destination_address_prefix = "*"
    destination_port_range     = "443"
  }

  // Outbound rules
  security_rule {
    priority                   = 100
    name                       = "out-ssh-rdp"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["22", "3389"]
  }

  security_rule {
    priority                   = 110
    name                       = "out-bastion-data-plane"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["8080", "5701"]
  }

  security_rule {
    priority                   = 120
    name                       = "out-azure"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "AzureCloud"
    destination_port_range     = "443"
  }

  security_rule {
    priority                   = 130
    name                       = "out-internet"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "*"
    source_port_range          = "*"
    destination_address_prefix = "Internet"
    destination_port_range     = "80"
  }
}

resource "azurerm_role_assignment" "bastion_login" {
  for_each = var.enable_ssh ? toset([
    "Virtual Machine Administrator Login",
    "Reader",
  ]) : []
  scope                = azurerm_resource_group.zone.id
  role_definition_name = each.value
  principal_id         = var.__enclave_infra.bastion_login_principal_id
}
