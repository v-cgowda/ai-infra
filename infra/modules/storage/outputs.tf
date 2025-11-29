# Storage Module Outputs

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_primary_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "container_urls" {
  description = "URLs of the created containers"
  value = {
    for name, container in azurerm_storage_container.containers :
    name => "${azurerm_storage_account.main.primary_blob_endpoint}${container.name}"
  }
}

output "file_share_urls" {
  description = "URLs of the created file shares"
  value = {
    for name, share in azurerm_storage_share.shares :
    name => "${azurerm_storage_account.main.primary_file_endpoint}${share.name}"
  }
}

output "private_endpoint_ids" {
  description = "Map of private endpoint IDs by subresource type"
  value       = { for k, v in azurerm_private_endpoint.storage : k => v.id }
}