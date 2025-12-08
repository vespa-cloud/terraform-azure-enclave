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

data "azurerm_subscription" "current" {}

locals {
  # NOTE: Do not rename or move this variable!
  # This is used by github actions to tag releases. Bump whenever making non-trivial changes.
  # Documentation changes are NOT considered minor and should bump the version.
  # To skip tagging for truly minor changes, mark the PR with a 'no-tag' label or start the PR title with 'minor'.
  template_version = "1.0.23"

  issuer_url = var.__zts_url

  main_region = "eastus"
  default_tags = {
    managed_by = "vespa_cloud"
  }
  athenz_domain        = "vespa.tenant.${var.tenant_name}.azure-${data.azurerm_subscription.current.subscription_id}"
  athenz_operator_role = "${local.athenz_domain}:role.azure.ssh-login"
}

resource "azurerm_resource_group" "system" {
  name     = "system"
  location = local.main_region
  tags     = merge(local.default_tags, { vespa_template_version = local.template_version })
}

// Uses the azapi provider to enable Encryption at Host feature for the subscription.
resource "azapi_resource_action" "enable_encryption_at_host" {
  type        = "Microsoft.Resources/subscriptions@2021-07-01"
  resource_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  action      = "/providers/Microsoft.Features/providers/Microsoft.Compute/features/EncryptionAtHost/register"
  body        = {}
}

resource "azurerm_user_assigned_identity" "tenant" {
  location            = local.main_region
  name                = "id-tenant"
  resource_group_name = azurerm_resource_group.system.name
  tags                = local.default_tags
}

# Custom role for archive storage accounts to allow blob write without delete.
# Role names must be unique tenant-wide, so we include the subscription id.
# Used by each zone's archive storage account
resource "azurerm_role_definition" "archive_writer_no_delete" {
  name        = "vespa-archive-writer-${data.azurerm_subscription.current.subscription_id}"
  scope       = data.azurerm_subscription.current.id
  description = "Allows writing archive blobs, without delete permissions."

  permissions {
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write"
    ]
  }
}
