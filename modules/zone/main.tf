terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

data "azurerm_location" "location" {
  location = var.zone.azure_region
}

locals {
  // The logical zone ID, e.g. "1"
  logical_zone_id = [for zone_mapping in data.azurerm_location.location.zone_mappings :
    zone_mapping.logical_zone if zone_mapping.physical_zone == var.zone.physical_zone][0]
}

resource "azurerm_resource_group" "zone" {
  name     = var.zone.short_name
  location = var.zone.azure_region
  tags = {
    zone = var.zone.name
    type = "zone"
  }
}

resource "azurerm_virtual_network" "zone" {
  name                = "network"
  address_space       = [var.network_ipv4_cidr, var.network_ipv6_cidr]
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name
  tags = {
    zone = var.zone.name
  }

  subnet {
    name              = "subnet-tenant"
    address_prefixes  = [cidrsubnet(var.network_ipv4_cidr, 1, 1), cidrsubnet(var.network_ipv6_cidr, 16, 2)]
    service_endpoints = ["Microsoft.Storage"]
    security_group    = azurerm_network_security_group.main.id
  }
}

resource "azurerm_public_ip" "natgw" {
  name                = "pip-natgw"
  resource_group_name = azurerm_resource_group.zone.name
  location            = azurerm_resource_group.zone.location
  zones               = [local.logical_zone_id]
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    zone = var.zone.name
  }
}
resource "azurerm_nat_gateway" "natgw" {
  name                = "natgw"
  location            = azurerm_resource_group.zone.location
  resource_group_name = azurerm_resource_group.zone.name
  sku_name            = "Standard"
  zones               = azurerm_public_ip.natgw.zones
  tags = {
    zone = var.zone.name
  }
}
resource "azurerm_nat_gateway_public_ip_association" "natgw" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.natgw.id
}
resource "azurerm_subnet_nat_gateway_association" "tenant" {
  subnet_id      = one([for s in azurerm_virtual_network.zone.subnet : s.id if s.name == "subnet-tenant"])
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-main"
  resource_group_name = azurerm_resource_group.zone.name
  location            = azurerm_resource_group.zone.location

  security_rule {
    priority                   = 110
    name                       = "in-endpoints"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_ranges    = ["443", "4443"]
  }

  security_rule {
    priority                   = 120
    name                       = "in-wireguard"
    direction                  = "Inbound"
    protocol                   = "Udp"
    access                     = "Allow"
    source_address_prefix      = "Internet"
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "51820"
  }

  tags = {
    zone = var.zone.name
  }
}
