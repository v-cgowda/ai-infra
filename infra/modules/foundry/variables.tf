# Foundry Module Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group (used as parent_id for azapi_resource)"
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

variable "project_identifier" {
  description = "Project identifier for resource naming. Should be short and alphanumeric."
  type        = string
}

variable "sku" {
  description = "SKU for Foundry service"
  type        = string
  default     = "S0"
}

variable "model_deployments" {
  description = "Foundry model deployments"
  type = list(object({
    name     = string
    sku_name = string
    capacity = number
    model = object({
      format  = string
      name    = string
      version = string
    })
  }))
  default = [
    {
      name     = "gpt-41-mini"
      sku_name = "GlobalStandard"
      capacity = 1
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1-mini"
        version = "2025-04-14"
      }
    },
    {
      name     = "gpt-41"
      sku_name = "GlobalStandard"
      capacity = 1
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
    }
  ]
}

variable "projects" {
  description = "List of Foundry projects to create"
  type = list(object({
    name         = string
    display_name = string
    description  = string
  }))
  default = []
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for Foundry VNet integration (optional)"
  type        = string
  default     = ""
}

variable "disable_local_auth" {
  description = "Disable local authentication (API key)"
  type        = bool
  default     = false
}

variable "public_network_access" {
  description = "Public network access setting (Enabled or Disabled)"
  type        = string
  default     = "Disabled"
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (private endpoint created if specified)"
  type        = string
  default     = ""
}

variable "private_dns_zone_ids" {
  description = "Private DNS zone IDs for Cognitive Services (cognitiveServices, azureOpenAI, servicesAiAzure)"
  type        = map(string)
  default     = {
    cognitiveServices = ""
    azureOpenAI       = ""
    servicesAiAzure   = ""
  }
}

variable "network_restrictions" {
  description = "Network access restrictions"
  type = object({
    default_action = string
    ip_rules       = list(string)
    virtual_network_rules = list(object({
      subnet_id = string
    }))
  })
  default = {
    default_action        = "Deny"
    ip_rules             = []
    virtual_network_rules = []
  }
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key (optional)"
  type        = string
  default     = ""
}

variable "app_insights_resource_id" {
  description = "Application Insights Resource ID (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}