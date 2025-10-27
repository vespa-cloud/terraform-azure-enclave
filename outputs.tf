locals {
  zones_by_env = {
    for zone in var.__all_zones :
    zone.environment => merge(
      {
        // The name of the Vespa Cloud zone, e.g. "prod.azure-eastus-az1"
        name = "${zone.environment}.azure-${zone.physical_zone}",
        // The short name of the Vespa Cloud zone, used e.g. in hostnames
        short_name   = "${zone.environment}.${zone.physical_zone}",
        region       = "azure-${zone.physical_zone}",
        azure_region = split("-", zone.physical_zone)[0],
      },
      zone
    )...
  }
}

output "zones" {
  description = "Map of available Vespa Cloud zones grouped by environment. Available zones are listed at https://cloud.vespa.ai/en/reference/zones.html. Reference a zone with `[environment].[region with - replaced by _]` (e.g. `prod.azure_eastus_az1`)."
  value = {
    for environment, zones in local.zones_by_env :
    environment => { for z in zones : replace(z.region, "-", "_") => z }
  }
}

data "azurerm_subscription" "current" {}

output "enclave_config" {
  description = "Configuration values that must be shared with the Vespa team to finalize the enclave setup: Azure AD application (client) id for Athenz, subscription id and tenant id."
  value = {
    "client_id" : module.provision.client_id,
    "subscription_id" : data.azurerm_subscription.current.subscription_id,
    "tenant_id" : data.azurerm_subscription.current.tenant_id
  }
}

output "__enclave_infra" {
  description = "Internal infrastructure details of the enclave module."
  value       = module.provision.enclave_infra
}
