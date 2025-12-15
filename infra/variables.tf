variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID to deploy environment into."
}

variable "resource_group_name" {
  type        = string
  description = "Name of existing resource group to deploy resources into."
}

variable "region" {
  type    = string
  default = "westus3"
  description = "Azure region to deploy resources."
}

variable "region_aifoundry" {
  type    = string
  default = "westus3"
  description = "Azure region to deploy AI Foundry resources."
}

variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Network range for created virtual network."
}

variable "utility_vm_admin_password" {
  type        = string
  description = "Admin password for utility VM."
  sensitive   = true
}

variable "github_token" {
  description = "GitHub token for runner registration"
  type        = string
  sensitive   = true
}

variable "github_runner_ssh_public_key_path" {
  description = "Path to the SSH public key file for GitHub runner VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "github_repository" {
  description = "GitHub repository to register the self-hosted runner with (e.g., user/repo)"
  type        = string
}

variable "function_app_source_control_url" {
  description = "URL path to function app source code. Specify subdirectory if needed. Leave empty to disable source control setup."
  type        = string
  sensitive   = false
  default     = ""
}