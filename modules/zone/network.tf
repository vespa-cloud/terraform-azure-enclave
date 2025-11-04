data "azurerm_location" "location" {
  location = var.zone.azure_region
}

locals {
  // The logical zone ID, e.g. "1"
  logical_zone_id = [for zone_mapping in data.azurerm_location.location.zone_mappings :
  zone_mapping.logical_zone if zone_mapping.physical_zone == var.zone.physical_zone][0]
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
    address_prefixes  = [local.tenant_network_ipv4, local.tenant_network_ipv6]
    service_endpoints = ["Microsoft.Storage"]
    security_group    = azurerm_network_security_group.main.id
  }

  subnet {
    #checkov:skip=CKV2_AZURE_31: Not needed (https://learn.microsoft.com/en-us/answers/questions/531182/nsg-required-for-bastion-subnet)
    name              = local.bastion_subnet_name
    address_prefixes  = [local.bastion_network_ipv4]
    service_endpoints = ["Microsoft.Storage"]
    security_group    = azurerm_network_security_group.bastion.id
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

  security_rule {
    priority                   = 130
    name                       = "in-bastion"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    access                     = "Allow"
    source_address_prefix      = local.bastion_network_ipv4
    source_port_range          = "*"
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "22"
  }

  tags = {
    zone = var.zone.name
  }
}

// --- Flow logs setup (no Traffic Analytics workspace) ---
// Enable NSG flow logs for each zone. Logs are stored in a per-zone Storage Account.
// Prerequisite: Regional Network Watcher must exist (Azure usually auto-creates
// it in resource group "NetworkWatcherRG" as "NetworkWatcher_<region>").
// ⚠️There can only be one network watcher per region per subscription.

// Look up the regional Network Watcher
data "azurerm_network_watcher" "this" {
  name                = "NetworkWatcher_${var.zone.azure_region}"
  resource_group_name = "NetworkWatcherRG"
}

// Random suffix to ensure a globally-unique storage account name
// ⚠️Storage account names must be unique across Azure, and only allow lowercase letters and numbers.
resource "random_string" "flowlogs_suffix" {
  length  = 6
  upper   = false
  special = false
}

// Storage account to store NSG flow logs for this zone
resource "azurerm_storage_account" "flow_logs_storage" {
  name                            = lower(replace(replace("flowlogs${var.zone.short_name}${random_string.flowlogs_suffix.result}", "-", ""), ".", ""))
  resource_group_name             = azurerm_resource_group.zone.name
  location                        = azurerm_resource_group.zone.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  tags = {
    zone = var.zone.name
  }
}

// Enable flow logs for main NSG (bastion flow log is set up in bastion.tf)
resource "azurerm_network_watcher_flow_log" "main" {
  name                 = "flowlogs-${var.zone.name}-main"
  network_watcher_name = data.azurerm_network_watcher.this.name
  resource_group_name  = data.azurerm_network_watcher.this.resource_group_name
  target_resource_id   = azurerm_network_security_group.main.id
  storage_account_id   = azurerm_storage_account.flow_logs_storage.id
  enabled              = true

  retention_policy {
    enabled = true
    days    = 30
  }
}
