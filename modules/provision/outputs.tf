output "archive_writer_role_id" {
  description = "The resource ID for the custom role: archive writer without delete."
  value       = azurerm_role_definition.archive_writer_no_delete.role_definition_resource_id
}
