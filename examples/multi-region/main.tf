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

#
# Set up the Azure Terraform Provider to point to the Azure subscription where
# you want to provision the Vespa Cloud Enclave.
#
provider "azurerm" {
  features {}
  subscription_id = "<YOUR-SUBSCRIPTION-ID>"

  # Necessary to create the archive Storage Account.
  # Ensure the principal running Terraform has appropriate RBAC on the storage account
  # (typically Storage Account Contributor at the account scope).
  storage_use_azuread = true
}

provider "azapi" {}

#
# Set up the basic module that grants Vespa Cloud permission to
# provision Vespa Cloud resources inside the Azure subscription.
#
module "enclave" {
  source      = "vespa-cloud/enclave/azure"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
}

#
# Create individual zone modules for the zones you want to provision.
# Each zone can have different configuration settings.
#

module "zone_test_azure_eastus_az1" {
  source  = "vespa-cloud/enclave/azure//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.test.azure_eastus_az1

  enable_ssh = false  # SSH disabled in test
}

module "zone_staging_azure_eastus_az1" {
  source  = "vespa-cloud/enclave/azure//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.staging.azure_eastus_az1

  enable_ssh = true  # SSH enabled for debugging in staging
}

module "zone_prod_azure_eastus_az1" {
  source  = "vespa-cloud/enclave/azure//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.prod.azure_eastus_az1

  enable_ssh                  = false  # SSH disabled in production
  archive_reader_principals   = []     # Add principal IDs that need archive access
}

module "zone_prod_azure_westeurope_az1" {
  source  = "vespa-cloud/enclave/azure//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.prod.azure_westeurope_az1

  enable_ssh                  = false  # SSH disabled in production
  archive_reader_principals   = []     # Add principal IDs that need archive access
}

#
# Output the enclave configuration that must be shared with Vespa team.
#
output "enclave_config" {
  description = "Share this configuration with the Vespa team to finalize enclave setup"
  value       = module.enclave.enclave_config
}
