
locals {
  subnet_name = "AzureBastionSubnet"
}

resource "azurerm_virtual_network" "bastion" {
  count = var.enable_ssh ? 1 : 0
  name                = "bastion"
  address_space       = [local.bastion_network_ipv4]
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name

  subnet {
    #checkov:skip=CKV2_AZURE_31: Not needed (https://learn.microsoft.com/en-us/answers/questions/531182/nsg-required-for-bastion-subnet)
    name                 = local.subnet_name
    address_prefixes     = [local.bastion_network_ipv4]
    service_endpoints = ["Microsoft.Storage"]
    security_group = azurerm_network_security_group.bastion[0].id
  }
}

resource "azurerm_public_ip" "bastion" {
  count = var.enable_ssh ? 1 : 0
  name                = "pip-bastion"
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  count = var.enable_ssh ? 1 : 0
  name                = "bastion"
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name
  sku                 = "Standard"
  tunneling_enabled   = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            =  "${azurerm_virtual_network.bastion[0].id}/subnets/${local.subnet_name}"
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

resource "azurerm_network_security_group" "bastion" {
  count = var.enable_ssh ? 1 : 0
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
