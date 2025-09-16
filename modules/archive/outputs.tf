
output "container" {
  description = "ID of Vespa Cloud Enclave archive storage container"
  value       = azurerm_storage_container.archive.id
}
