# Test fixture: composes the root module with the customer-facing zone
# submodule, mirroring the basic example, but with relative sources so the
# local (unreleased) code is what gets planned. enable_ssh exercises the
# optional bastion resources.

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

module "enclave" {
  source      = "../.."
  tenant_name = "vespa"
}

module "zone" {
  source     = "../../modules/zone"
  zone       = module.enclave.zones.dev.azure_eastus_az1
  enable_ssh = true
  archive_reader_principals = [
    "44444444-4444-4444-4444-444444444444",
  ]
  key_officers = [
    "55555555-5555-5555-5555-555555555555",
  ]
}

output "enclave_config" {
  value = module.enclave.enclave_config
}
