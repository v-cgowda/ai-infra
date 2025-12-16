# Function Apps Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "service_plan_sku" {
  description = "SKU for the service plan"
  type        = string
  validation {
    condition     = contains(["EP1", "EP2", "EP3"], var.service_plan_sku)
    error_message = "The service_plan_sku must be one of: EP1, EP2, EP3."
  }
}

variable "storage_account_name" {
  description = "Storage account name for Function App"
  type        = string
}

variable "storage_account_access_key" {
  description = "Storage account access key (optional, AzureWebJobsStorage setting only populated if specified)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "enable_system_assigned_identity" {
  description = "Enable System Assigned Managed Identity. If false, will use User Assigned Identity if managed_identity_id is provided."
  type        = bool
  default     = true
}

variable "managed_identity_id" {
  description = "Managed identity ID for accessing resources (optional, used when enable_system_assigned_identity is false)"
  type        = string
  default     = ""
}

variable "application_insights_key" {
  description = "Application Insights instrumentation key"
  type        = string
  sensitive   = true
}

variable "application_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  sensitive   = true
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration (optional)"
  type        = string
  default     = ""
}

variable "public_access_enabled" {
  description = "Enable public network access for Function Apps. Default is false."
  type        = bool
  default     = false
}

variable "function_apps" {
  description = "Configuration for Linux function apps"
  type = list(object({
    name                    = string
    runtime_stack          = string # "python", "node", "dotnet", "java"
    runtime_version        = string
    always_on              = bool
    app_settings           = map(string)
    connection_strings     = map(string)
    enable_vnet_integration = bool
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for Function Apps"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (private endpoint created if specified)"
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for function apps (privatelink.azurewebsites.net)"
  type        = string
  default     = ""
}

