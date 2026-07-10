# Plan-only smoke test with mocked Azure providers. Runs without credentials.
#
# Catches plan-time regressions: broken variable wiring, for_each/count
# errors, type mismatches, invalid references between the root module and
# the customer-facing zone submodule.

mock_provider "azurerm" {
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "11111111-1111-1111-1111-111111111111"
    }
  }
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      client_id       = "22222222-2222-2222-2222-222222222222"
      object_id       = "33333333-3333-3333-3333-333333333333"
    }
  }

  # The zone module resolves the logical zone id from the region's
  # physical->logical zone mappings; the fixture's zone must be present.
  mock_data "azurerm_location" {
    defaults = {
      zone_mappings = [
        {
          logical_zone  = "1"
          physical_zone = "eastus-az1"
        },
      ]
    }
  }

  # Computed attributes that are parsed/validated at plan time need
  # plausible fake values instead of the auto-generated random strings.
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/system/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-mock"
      principal_id = "66666666-6666-6666-6666-666666666666"
      client_id    = "77777777-7777-7777-7777-777777777777"
    }
  }
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
    }
  }
  mock_resource "azurerm_role_definition" {
    defaults = {
      role_definition_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/88888888-8888-8888-8888-888888888888"
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/vault-mock"
    }
  }
  mock_resource "azurerm_key_vault_key" {
    defaults = {
      id             = "https://vault-mock.vault.azure.net/keys/key-mock/0123456789abcdef0123456789abcdef"
      versionless_id = "https://vault-mock.vault.azure.net/keys/key-mock"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Storage/storageAccounts/samock"
    }
  }
  mock_resource "azurerm_storage_container" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Storage/storageAccounts/samock/blobServices/default/containers/container-mock"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/network"
    }
  }
  mock_resource "azurerm_public_ip" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/publicIPAddresses/pip-mock"
    }
  }
  mock_resource "azurerm_nat_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/natGateways/natgw-mock"
    }
  }
}

mock_provider "azapi" {}

# Plan the root module on its own, with only the required variable set.
run "root_module" {
  command = plan

  variables {
    tenant_name = "smoke"
  }

  assert {
    condition     = output.zones.dev.azure_eastus_az1.short_name == "dev.eastus-az1"
    error_message = "unexpected short_name for zones.dev.azure_eastus_az1"
  }

  assert {
    condition     = output.zones.dev.azure_eastus_az1.azure_region == "eastus"
    error_message = "azure_region not derived from physical_zone as expected"
  }

  # The static zones output (outputs_zones.tf) must stay consistent with the
  # dynamic computation from var.__all_zones.
  assert {
    condition     = output.zones.dev.azure_eastus_az1 == output.__test_zones.dev.azure_eastus_az1
    error_message = "static zones output disagrees with dynamically computed zones"
  }

  assert {
    condition     = output.enclave_config.subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "enclave_config.subscription_id not taken from the subscription data source"
  }
}

# Plan the full customer-shaped composition (root + zone) against the
# local code.
run "full_composition" {
  command = plan

  module {
    source = "./tests/full"
  }

  assert {
    condition     = output.enclave_config.vespa_tenant_name == "vespa"
    error_message = "enclave_config.vespa_tenant_name not wired from tenant_name"
  }
}
