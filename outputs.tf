locals {
  zones_by_env = {
    for zone in var.all_zones :
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
  description = "Available zones are listed at https://cloud.vespa.ai/en/reference/zones.html . You reference a zone with `[environment].[region with - replaced by _]` (e.g `prod.azure_eastus_az1`)."
  value = {
    for environment, zones in local.zones_by_env :
    environment => { for zone in zones : replace(zone.region, "-", "_") => zone }
  }
}
