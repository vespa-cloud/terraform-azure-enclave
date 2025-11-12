# Temporary file for state migration from provision module to root
# This file can be safely deleted after the first successful apply

# Resource group
moved {
  from = module.provision.azurerm_resource_group.system
  to   = azurerm_resource_group.system
}

# Feature registration
moved {
  from = module.provision.azapi_resource_action.enable_encryption_at_host
  to   = azapi_resource_action.enable_encryption_at_host
}

# Identities
moved {
  from = module.provision.azurerm_user_assigned_identity.tenant
  to   = azurerm_user_assigned_identity.tenant
}

moved {
  from = module.provision.azurerm_user_assigned_identity.provisioner
  to   = azurerm_user_assigned_identity.provisioner
}

moved {
  from = module.provision.azurerm_user_assigned_identity.athenz
  to   = azurerm_user_assigned_identity.athenz
}

moved {
  from = module.provision.azurerm_user_assigned_identity.id_operator
  to   = azurerm_user_assigned_identity.id_operator
}

moved {
  from = module.provision.azurerm_user_assigned_identity.controller
  to   = azurerm_user_assigned_identity.controller
}

# Federated credentials
moved {
  from = module.provision.azurerm_federated_identity_credential.provisioner
  to   = azurerm_federated_identity_credential.provisioner
}

moved {
  from = module.provision.azurerm_federated_identity_credential.athenz
  to   = azurerm_federated_identity_credential.athenz
}

moved {
  from = module.provision.azurerm_federated_identity_credential.athenz_443
  to   = azurerm_federated_identity_credential.athenz_443
}

moved {
  from = module.provision.azurerm_federated_identity_credential.id_operator
  to   = azurerm_federated_identity_credential.id_operator
}

moved {
  from = module.provision.azurerm_federated_identity_credential.controller
  to   = azurerm_federated_identity_credential.controller
}

# Role definitions
moved {
  from = module.provision.azurerm_role_definition.provisioner
  to   = azurerm_role_definition.provisioner
}

moved {
  from = module.provision.azurerm_role_definition.athenz
  to   = azurerm_role_definition.athenz
}

moved {
  from = module.provision.azurerm_role_definition.archive_writer_no_delete
  to   = azurerm_role_definition.archive_writer_no_delete
}

moved {
  from = module.provision.azurerm_role_definition.controller_archive
  to   = azurerm_role_definition.controller_archive
}

moved {
  from = module.provision.azurerm_role_definition.controller_system
  to   = azurerm_role_definition.controller_system
}

# Role assignments
moved {
  from = module.provision.azurerm_role_assignment.provisioner
  to   = azurerm_role_assignment.provisioner
}

moved {
  from = module.provision.azurerm_role_assignment.azure
  to   = azurerm_role_assignment.azure
}

moved {
  from = module.provision.azurerm_role_assignment.id_operator
  to   = azurerm_role_assignment.id_operator
}

moved {
  from = module.provision.azurerm_role_assignment.controller_archive
  to   = azurerm_role_assignment.controller_archive
}

moved {
  from = module.provision.azurerm_role_assignment.controller_system
  to   = azurerm_role_assignment.controller_system
}
