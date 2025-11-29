# Container Apps Module Outputs

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_environment_default_domain" {
  description = "Default domain of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "container_app_environment_static_ip" {
  description = "Static IP address of the Container Apps Environment"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "container_apps" {
  description = "Information about the created container apps"
  value = {
    for name, app in azurerm_container_app.apps : name => {
      id       = app.id
      name     = app.name
      fqdn     = try(app.ingress[0].fqdn, null)
      revision = app.latest_revision_name
    }
  }
}

output "container_app_urls" {
  description = "URLs of container apps with external ingress"
  value = {
    for name, app in azurerm_container_app.apps :
    name => try("https://${app.ingress[0].fqdn}", null)
    if try(app.ingress[0].external_enabled, false)
  }
}

output "private_endpoint_id" {
  description = "ID of the private endpoint for Container Apps Environment"
  value       = var.private_endpoint_subnet_id != "" ? azurerm_private_endpoint.container_apps_environment[0].id : null
}