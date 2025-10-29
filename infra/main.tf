locals {
  identifier = random_string.naming.result
  prefix = "invoice-ai-${random_string.naming.result}"
  tags = {
    Environment = "Demo"
    Owner       = lookup(data.external.me.result, "name")
  }
}

resource "azurerm_resource_group" "shared_rg" {
  name     = "${local.prefix}-rg"
  location = var.region
  tags     = local.tags
}

data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {}

resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}