variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region location"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = "Map of subnets to create with their configurations"
  type = map(object({
    address_prefix = string
    nsg_name       = optional(string)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    }))
  }))
  default = {}
}

variable "network_security_groups" {
  description = "Map of network security groups to create"
  type        = map(object({
    name = string
  }))
  default = {}
}

variable "enable_private_dns_zones" {
  description = "Whether to create private DNS zones"
  type        = bool
  default     = true
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type = list(object({
    name         = string
    zone_name    = string
    description  = string
  }))
  default = [
    {
      name         = "storage_blob"
      zone_name    = "privatelink.blob.core.windows.net"
      description  = "Private DNS zone for Storage Account Blob service"
    },
    {
      name         = "container_registry"
      zone_name    = "privatelink.azurecr.io"
      description  = "Private DNS zone for Container Registry"
    },
    {
      name         = "keyvault"
      zone_name    = "privatelink.vaultcore.azure.net"
      description  = "Private DNS zone for Key Vault"
    },
    {
      name         = "functions"
      zone_name    = "privatelink.azurewebsites.net"
      description  = "Private DNS zone for Function Apps"
    },
    {
      name         = "container_apps"
      zone_name    = "privatelink.*.azurecontainerapps.io"
      description  = "Private DNS zone for Container Apps"
    },
    {
      name         = "cosmos"
      zone_name    = "privatelink.documents.azure.com"
      description  = "Private DNS zone for Cosmos DB"
    },
    {
      name         = "cognitive_services"
      zone_name    = "privatelink.cognitiveservices.azure.com"
      description  = "Private DNS zone for Cognitive Services"
    },
    {
      name         = "openai"
      zone_name    = "privatelink.openai.azure.com"
      description  = "Private DNS zone for Azure Open AI"
    },
    {
      name         = "ai_foundry"
      zone_name    = "privatelink.api.azureml.ms"
      description  = "Private DNS zone for AI Foundry"
    }
  ]
}