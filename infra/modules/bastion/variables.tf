variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network. Not required for the Developer SKU"
  type        = string
  default     = "null"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the AzureBastionSubnet (minimum /26). Required for Basic and Standard SKUs, not required for Developer SKU."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "sku" {
  description = "SKU of the Bastion Host (Developer, Basic, or Standard)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Developer", "Basic", "Standard"], var.sku)
    error_message = "SKU must be either Developer, Basic, or Standard."
  }
}

variable "scale_units" {
  description = "Number of scale units for the Bastion Host (2-50, only applicable to Standard SKU)"
  type        = number
  default     = 2
  validation {
    condition     = var.scale_units >= 2 && var.scale_units <= 50
    error_message = "Scale units must be between 2 and 50."
  }
}

variable "enable_tunneling" {
  description = "Enable native client support (tunneling). Only available with Standard SKU"
  type        = bool
  default     = true
}

variable "enable_ip_connect" {
  description = "Enable IP-based connection. Only available with Standard SKU"
  type        = bool
  default     = true
}

variable "enable_shareable_link" {
  description = "Enable shareable link. Only available with Standard SKU"
  type        = bool
  default     = false
}

variable "enable_file_copy" {
  description = "Enable file copy. Only available with Standard SKU"
  type        = bool
  default     = true
}

variable "copy_paste_enabled" {
  description = "Enable copy/paste functionality"
  type        = bool
  default     = true
}
