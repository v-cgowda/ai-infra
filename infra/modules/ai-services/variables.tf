# AI Services Module Variables

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

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets (optional)"
  type        = string
  default     = ""
}

variable "form_recognizer_enabled" {
  description = "Enable Azure Form Recognizer (Document Intelligence)"
  type        = bool
  default     = true
}

variable "computer_vision_enabled" {
  description = "Enable Azure Computer Vision"
  type        = bool
  default     = false
}

variable "private_endpoint_info" {
  description = "Private endpoint configuration (subnet_id and dns_zone_id)"
  type = object({
    subnet_id    = string
    dns_zone_id  = string
  })
  default = null
  nullable = true
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
