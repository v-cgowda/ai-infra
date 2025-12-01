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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "current_user_object_id" {
  description = "Object ID of the current user"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Key Vault private endpoint"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for Key Vault"
  type        = string
}

variable "managed_identities" {
  description = "List of managed identities to create"
  type = list(object({
    name        = string
    description = string
  }))
  default = [
    {
      name        = "funcapp-identity"
      description = "Identity for function app to access other resources"
    },
    {
      name        = "containerapp-identity"
      description = "Identity for container app to pull images from ACR"
    },
    {
      name        = "github-runner-identity"
      description = "Identity for GitHub runner VM for Azure operations"
    }
  ]
}