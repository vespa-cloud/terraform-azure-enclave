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
  template_version = "0.0.1"
  zts_prod         = "https://zts.athenz.vespa-cloud.com:4443/zts/v1"
  zts_cd           = "https://zts.athenz.cd.vespa-cloud.com:4443/zts/v1"
  issuer_url       = var.athenz_env == "cd" ? local.zts_cd : local.zts_prod
}

module "provision" {
  source           = "./modules/provision"
  tenant_name      = var.tenant_name
  template_version = local.template_version
  issuer_url       = local.issuer_url
}
