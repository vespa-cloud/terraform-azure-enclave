output "client_id" {
  description = "Azure AD application (client) id of the user-assigned managed identity used by Athenz."
  value       = azurerm_user_assigned_identity.athenz.client_id
}

output "enclave_infra" {
  description = "Object containing resources for enclave infrastructure."
  value = {
    archive_writer_role_resource_id = azurerm_role_definition.archive_writer_no_delete.role_definition_resource_id
    bastion_login_principal_id      = azurerm_user_assigned_identity.bastion_login.principal_id
  }
}
