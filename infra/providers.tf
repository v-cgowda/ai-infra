terraform {
  required_providers {
    azurerm = "~> 4.0"
    random  = "~> 3.6"
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  storage_use_azuread = true
}

provider "azapi" {
  subscription_id = var.subscription_id
}
