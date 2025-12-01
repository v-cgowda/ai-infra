output "container_registry_id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_login_server" {
  description = "Login server of the Container Registry"
  value       = azurerm_container_registry.main.login_server
}