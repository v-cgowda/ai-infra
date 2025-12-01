# Function Apps Module Outputs

output "service_plan_id" {
  description = "IDs of the service plans"
  value       = azurerm_service_plan.app_service_plan.id
}

output "function_apps" {
  description = "Information about function apps"
  value = {
    for name, app in azurerm_linux_function_app.apps : name => {
      id                    = app.id
      name                  = app.name
      default_hostname      = app.default_hostname
      principal_id          = app.identity[0].principal_id
      outbound_ip_addresses = app.outbound_ip_addresses
    }
  }
}

output "function_app_urls" {
  description = "URLs of all function apps"
  value = {
    for name, app in azurerm_linux_function_app.apps :
    name => "https://${app.default_hostname}"
  }
}

output "function_app_identities" {
  description = "Managed identities of function apps"
  value = {
    for name, app in azurerm_linux_function_app.apps :
    name => app.identity[0].principal_id
  }
}

output "private_endpoint_ids" {
  description = "IDs of the private endpoints for function apps"
  value       = { for k, v in azurerm_private_endpoint.function_app_pe : k => v.id }
}