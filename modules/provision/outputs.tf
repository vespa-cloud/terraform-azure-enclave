output "client_id" {
  description = "Azure AD application (client) id of the user-assigned managed identity used by Athenz."
  value       = azurerm_user_assigned_identity.athenz.client_id
}

output "archive_writer_role_id" {
  description = "The resource ID for the custom role: archive writer without delete."
  value       = azurerm_role_definition.archive_writer_no_delete.role_definition_resource_id
}
