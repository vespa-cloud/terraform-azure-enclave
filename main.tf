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

locals {
  # NOTE: Do not rename or move this variable!
  # This is used by github actions to tag releases. Bump whenever making non-trivial changes.
  # Documentation changes are NOT considered minor and should bump the version.
  # To skip tagging for truly minor changes, mark the PR with a 'no-tag' label or start the PR title with 'minor'.
  template_version = "1.0.20"

  issuer_url = var.__zts_url
}

module "provision" {
  source           = "./modules/provision"
  tenant_name      = var.tenant_name
  template_version = local.template_version
  issuer_url       = local.issuer_url
  operators        = var.__operators
}
