# Storage Module Variables

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

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "enable_versioning" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "enable_soft_delete" {
  description = "Enable soft delete for blobs"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft deleted blobs"
  type        = number
  default     = 30
}

variable "containers" {
  description = "List of storage containers to create"
  type = list(object({
    name   = string
    access = string
  }))
  default = [
    {
      name   = "invoices"
      access = "private"
    },
    {
      name   = "processed"
      access = "private"
    },
    {
      name   = "archive"
      access = "private"
    }
  ]
}

variable "file_shares" {
  description = "List of file shares to create"
  type = list(object({
    name  = string
    quota = number
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_network_access_enabled" {
  description = "Enable public network access to storage account"
  type        = bool
  default     = true
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace for Data Lake"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (private endpoints created if specified)"
  type        = string
  default     = ""
}

variable "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs for private endpoint (blob, file, dfs, table, queue, web)"
  type        = map(string)
  default     = {
    blob  = ""
    file  = ""
    dfs   = ""
    table = ""
    queue = ""
    web   = ""
  }
}