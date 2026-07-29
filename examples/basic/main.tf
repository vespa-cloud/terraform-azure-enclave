terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.7"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

#
# Set up the Azure Terraform Provider to point to the Azure subscription where
# your want to provision the Vespa Cloud Enclave.
#
provider "azurerm" {
  features {}
  subscription_id = "<YOUR-SUBSCRIPTION-ID>"

  # Necessary to create the archive Storage Account.
  # Ensure the principal running Terraform has appropriate RBAC on the storage account
  # (typically Storage Account Contributor at the account scope).
  storage_use_azuread = true

  # From azurerm 5.0 no resource providers are registered automatically.
  # These are the ones this module needs. Registration is idempotent, so the
  # list is safe to keep even if they are already registered.
  resource_providers_to_register = [
    "Microsoft.Compute",
    "Microsoft.KeyVault",
    "Microsoft.ManagedIdentity",
    "Microsoft.Network",
    "Microsoft.Storage",
  ]
}

provider "azapi" {}

#
# Set up the basic module that grants Vespa Cloud permission to
# provision Vespa Cloud resources inside the Azure subscription.
#
module "enclave" {
  source      = "vespa-cloud/enclave/azure"
  version     = ">= 1.1.0, < 2.0.0"
  tenant_name = "<YOUR-VESPA-TENANT-NAME>"
}

#
# Set up the VNet that will contain the Enclave Vespa application for the dev environment.
#
module "zone_dev_azure_eastus_az1" {
  source  = "vespa-cloud/enclave/azure//modules/zone"
  version = ">= 1.1.0, < 2.0.0"
  zone    = module.enclave.zones.dev.azure_eastus_az1

  # Allow Vespa Cloud operators to SSH into the provisioned VMs for troubleshooting.
  #enable_ssh = true
}

output "enclave_config" {
  value = module.enclave.enclave_config
}
