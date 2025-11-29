# outputs-modular.tf - Outputs for modular configuration

# General Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.shared_rg.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.shared_rg.location
}

# Networking Outputs
output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = module.networking.virtual_network_id
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = module.networking.subnet_ids
}

# Security Outputs
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}

output "managed_identity_ids" {
  description = "Map of managed identity names to IDs"
  value       = module.security.managed_identity_ids
}

# GitHub Runner Outputs  
output "github_runner_client_id" {
  description = "Client ID of the GitHub runner managed identity"
  value       = module.security.managed_identity_client_ids["github-runner-identity"]
}

output "github_runner_principal_id" {
  description = "Principal ID of the GitHub runner managed identity"
  value       = module.security.managed_identity_principal_ids["github-runner-identity"]
}

output "azure_tenant_id" {
  description = "Azure tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

# Container Registry Outputs
output "container_registry_login_server" {
  description = "Login server for the container registry"
  value       = azurerm_container_registry.invoiceapi.login_server
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.invoiceapi.name
}

# Observability Outputs
output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.observability.application_insights_connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.observability.log_analytics_workspace_id
}

# Storage Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "storage_container_urls" {
  description = "URLs of storage containers"
  value       = module.storage.container_urls
}

# Container Apps Outputs
output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = module.container_apps.container_app_environment_name
}

output "container_app_urls" {
  description = "URLs of container apps"
  value       = module.container_apps.container_app_urls
}

# Function Apps Outputs
output "function_app_urls" {
  description = "URLs of function apps"
  value       = module.function_apps.function_app_urls
}

# AI Services Outputs
output "ai_service_endpoints" {
  description = "AI service endpoints"
  value       = module.ai_services.service_endpoints
  sensitive   = true
}

output "openai_deployments" {
  description = "OpenAI model deployments"
  value       = module.ai_services.openai_deployments
}