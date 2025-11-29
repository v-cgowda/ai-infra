# Cosmos Module Variables

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

variable "offer_type" {
  description = "Cosmos DB offer type"
  type        = string
  default     = "Standard"
}

variable "kind" {
  description = "Cosmos DB kind (GlobalDocumentDB, MongoDB, etc.)"
  type        = string
  default     = "GlobalDocumentDB"
}

variable "consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Session"
}

variable "public_network_access_enabled" {
  description = "Enable public network access to Cosmos DB account"
  type        = bool
  default     = false
}

variable "capabilities" {
  description = "List of Cosmos DB capabilities (e.g., EnableServerless)"
  type        = list(string)
  default     = ["EnableServerless"]
}

variable "databases" {
  description = "List of SQL databases to create"
  type = list(object({
    name = string
  }))
  default = []
}

variable "containers" {
  description = "List of SQL containers to create"
  type = list(object({
    name                  = string
    database_name         = string
    partition_key_paths   = list(string)
    partition_key_version = number
  }))
  default = []
}

variable "private_endpoint_info" {
  description = "Private endpoint configuration (subnet_id and dns_zone_id)"
  type = object({
    subnet_id   = string
    dns_zone_id = string
  })
  default = {
    subnet_id   = ""
    dns_zone_id = ""
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
