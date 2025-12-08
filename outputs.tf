locals {
  // Builds a map from environment => list of zones for that environment.
  // Each zone object is enriched with derived fields
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

  // Enclave infrastructure object (used internally by zone objects)
  enclave_infra = {
    tenant_name                     = var.tenant_name
    archive_writer_role_resource_id = azurerm_role_definition.archive_writer_no_delete.role_definition_resource_id
    id_tenant_principal_id          = azurerm_user_assigned_identity.tenant.principal_id
    id_operator_principal_id        = azurerm_user_assigned_identity.id_operator.principal_id
    operator_role_definition_id     = azurerm_role_definition.bastion_vm_connect_reader.role_definition_resource_id
  }
}

// Internal test-only output exposing every zone from var.__all_zones (overridable).
// Regular consumers must use output "zones" in outputs_zones.tf to get IDE auto-completion for default zones.
// Not for production use; avoid depending on "__test_zones" outside tests.
output "__test_zones" {
  description = "Dynamic map of zones computed from var.__all_zones (for internal tests only)."
  # Create nested map structure: env → region_with_underscores → zone_object
  value = {
    for environment, zones in local.zones_by_env :
    environment => {
      for z in zones :
      replace(z.region, "-", "_") => merge(z, {
        enclave_infra = local.enclave_infra
      })
    }
  }
}

output "enclave_config" {
  description = "Configuration values that must be shared with the Vespa team to finalize the enclave setup: Azure AD application (client) id for Athenz, subscription id and tenant id."
  value = {
    "vespa_tenant_name" : var.tenant_name,
    "id_athenz_client_id" : azurerm_user_assigned_identity.athenz.client_id,
    "subscription_id" : data.azurerm_subscription.current.subscription_id,
    "azure_tenant_id" : data.azurerm_subscription.current.tenant_id
  }
}
