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

variable "subnet_id" {
  description = "Subnet ID for the VM"
  type        = string
}

variable "vm_name" {
  description = "Name suffix for the VM (will be prefixed)"
  type        = string
  default     = "vm"
}

variable "computer_name" {
  description = "Computer name for the VM"
  type        = string
  default     = "vmhost"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "os_disk_caching" {
  description = "OS disk caching type"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "Premium_LRS"
}

variable "image" {
  description = "VM image configuration"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-25h2-pro"
    version   = "latest"
  }
}

variable "custom_data" {
  description = "Custom data for VM initialization (optional). This must be a base64-encoded string."
  type        = string
  default     = ""
}

variable "setup_script" {
  description = "PowerShell script content to execute on VM startup using Custom Script Extension (optional)"
  type        = string
  default     = ""
}

variable "setup_script_name" {
  description = "Name for the setup script file"
  type        = string
  default     = "setup.ps1"
}
