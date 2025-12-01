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

variable "private_dns_zone_names" {
  description = "List of private DNS zone names to create (must match names in local.private_dns_zones)"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for zone in var.private_dns_zone_names : contains(
        ["storage_blob", "container_registry", "keyvault", "functions", "container_apps", "cosmosdb", "cognitive_services", "openai", "ai_services"],
        zone
      )
    ])
    error_message = "Each zone name must be one of: storage_blob, container_registry, keyvault, functions, container_apps, cosmosdb, cognitive_services, openai, ai_services"
  }

  default = []
}