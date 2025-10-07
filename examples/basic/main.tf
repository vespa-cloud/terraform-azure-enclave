
#
# Set up the Azure Terraform Provider to point to the Azure subscription where
# your want to provision the Vespa Cloud Enclave.
#
provider "azurerm" {
  features {}
  subscription_id = "<YOUR-SUBSCRIPTION-ID-HERE>"

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
  source      = "github.com/vespa-cloud/terraform-azure-enclave"
  version     = ">= 1.0.0, < 2.0.0"
  tenant_name = "<YOUR-TENANT-NAME-HERE>"
}

#
# Set up the VPC that will contain the Enclave Vespa application for the dev environment.
#
module "zone_dev_azure_eastus_az1" {
  source  = "github.com/vespa-cloud/terraform-azure-enclave//modules/zone"
  version = ">= 1.0.0, < 2.0.0"
  zone    = module.enclave.zones.dev.azure_eastus_az1
}
