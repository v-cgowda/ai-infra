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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "SKU for the Container Registry"
  type        = string
  default     = "Premium"
}

variable "public_network_access_enabled" {
  description = "Enable public network access to Container Registry"
  type        = bool
  default     = false
}

variable "anonymous_pull_enabled" {
  description = "Enable anonymous pull for Container Registry"
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