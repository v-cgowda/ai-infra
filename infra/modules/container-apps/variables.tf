# Container Apps Module Variables

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

variable "subnet_id" {
  description = "Subnet ID for Container Apps Environment"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for monitoring"
  type        = string
}

variable "container_registry_id" {
  description = "Container Registry ID for pulling images"
  type        = string
}

variable "container_registry_server" {
  description = "Container Registry server URL"
  type        = string
}

variable "managed_identity_id" {
  description = "Managed identity ID for accessing resources."
  type        = string
}

variable "container_apps" {
  description = "Configuration for container apps"
  type = list(object({
    name          = string
    image         = string
    cpu           = number
    memory        = string
    min_replicas  = number
    max_replicas  = number
    target_port   = number
    external_ingress = bool
    env_vars = list(object({
      name  = string
      value = string
    }))
    secrets = list(object({
      name  = string
      value = string
    }))
    workload_profile_name = string
  }))
}

variable "dapr_enabled" {
  description = "Enable Dapr for the Container Apps Environment"
  type        = bool
  default     = false
}

variable "public_network_access" {
  description = "Public network access for Container Apps Environment (Enabled or Disabled)"
  type        = string
  default     = "Disabled"
}

variable "workload_profiles" {
  description = "Workload profiles for Container Apps Environment"
  type = list(object({
    name                  = string
    workload_profile_type = string
    maximum_count         = number
    minimum_count         = number
  }))
  default = [
    {
      name                  = "internal-small"
      workload_profile_type = "D4"
      maximum_count         = 10
      minimum_count         = 1
    }
  ]
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (private endpoint created if specified)"
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for Container Apps Environment"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}