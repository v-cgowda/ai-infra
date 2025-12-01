# main.tf - Modular Infrastructure Configuration

# Data sources
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}

# Local values
locals {
  identifier = random_string.naming.result
  prefix     = random_string.naming.result
  tags = {
    Environment     = "Demo"
    Owner          = lookup(data.external.me.result, "name")
    SecurityControl = "Ignore"
    ManagedBy      = "Terraform"
  }
}

# Random naming
resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

# Resource Group
resource "azurerm_resource_group" "shared_rg" {
  name     = "${local.prefix}-shared-rg"
  location = var.region
  tags     = local.tags
}
