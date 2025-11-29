# main.tf - Modular Infrastructure Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}

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
  name     = local.prefix
  location = var.region
  tags     = local.tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  cidr                = var.cidr
  tags                = local.tags
  
  # Define Network Security Groups
  network_security_groups = {
    dmz = {
      name = "dmz"
    }
    compute = {
      name = "compute"
    }
  }
  
  # Define Subnets with their configurations
  subnets = {
    dmz = {
      address_prefix = cidrsubnet(var.cidr, 8, 0)
      nsg_name       = "dmz"
    }
    services = {
      address_prefix = cidrsubnet(var.cidr, 8, 1)
      nsg_name       = "compute"
    }
    functionapps = {
      address_prefix = cidrsubnet(var.cidr, 8, 2)
      nsg_name       = "compute"
      delegation = {
        name = "function-apps-delegation"
        service_delegation = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    utility = {
      address_prefix = cidrsubnet(var.cidr, 8, 3)
      nsg_name       = null
    }
    containerapps = {
      address_prefix = cidrsubnet(var.cidr, 7, 4)
      nsg_name       = "compute"
      delegation = {
        name = "container-app-delegation"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }
    }
    aifoundry = {
      address_prefix = cidrsubnet(var.cidr, 8, 6)
      nsg_name       = "compute"
    }
  }
}

# Observability Module
module "observability" {
  source = "./modules/observability"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  tags                = local.tags
}

# Security Module
module "security" {
  source = "./modules/security"

  prefix                 = local.prefix
  resource_group_name    = azurerm_resource_group.shared_rg.name
  location               = azurerm_resource_group.shared_rg.location
  tenant_id              = data.azurerm_client_config.current.tenant_id
  current_user_object_id = data.azurerm_client_config.current.object_id
  subnet_id              = module.networking.subnet_ids.services
  private_dns_zone_id    = module.networking.private_dns_zone_ids.keyvault
  tags                   = local.tags
}

# GitHub Runner Module
module "github_runner" {
  source = "./modules/github-runner"

  prefix                        = local.prefix
  resource_group_name           = azurerm_resource_group.shared_rg.name
  location                      = azurerm_resource_group.shared_rg.location
  subnet_id                     = module.networking.subnet_ids.utility
  managed_identity_id           = module.security.managed_identity_ids["github-runner-identity"]
  managed_identity_principal_id = module.security.managed_identity_principal_ids["github-runner-identity"]
  subscription_id               = var.subscription_id
  container_registry_id         = azurerm_container_registry.invoiceapi.id
  github_repository             = var.github_repository
  github_token                  = var.github_token
  ssh_public_key_path           = var.github_runner_ssh_public_key_path
  tags                          = local.tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  resource_group_name = azurerm_resource_group.shared_rg.name
  location           = azurerm_resource_group.shared_rg.location
  environment        = "demo"
  project_name       = local.prefix
  
  # Storage configuration
  storage_account_tier        = "Standard"
  storage_account_replication = "LRS"
  enable_versioning          = true
  enable_soft_delete         = true
  
  containers = [
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
  
  # Private endpoint configuration
  private_endpoint_subnet_id  = module.networking.subnet_ids.services
  private_dns_zone_ids = {
    blob = module.networking.private_dns_zone_ids.storage_blob
  }
  
  tags = local.tags
}

# Container Apps Module
module "container_apps" {
  source = "./modules/container-apps"
  
  resource_group_name = azurerm_resource_group.shared_rg.name
  location           = azurerm_resource_group.shared_rg.location
  environment        = "demo"
  project_name       = local.prefix
  
  # Dependencies
  subnet_id                    = module.networking.subnet_ids.containerapps
  log_analytics_workspace_id   = module.observability.log_analytics_workspace_id
  container_registry_id        = azurerm_container_registry.invoiceapi.id
  container_registry_server    = azurerm_container_registry.invoiceapi.login_server
  managed_identity_id          = module.security.managed_identity_ids["container-apps-identity"]
  
  # Private endpoint configuration
  private_endpoint_subnet_id  = module.networking.subnet_ids.services
  private_dns_zone_id         = module.networking.private_dns_zone_ids.container_apps
  
  # Container apps configuration (empty for now)
  container_apps = []
  dapr_enabled   = true
  
  tags = local.tags
}

# Function Apps Module
module "function_apps" {
  source = "./modules/function-apps"
  
  resource_group_name = azurerm_resource_group.shared_rg.name
  location           = azurerm_resource_group.shared_rg.location
  environment        = "demo"
  project_name       = local.prefix
  
  # Dependencies
  storage_account_name                   = module.storage.storage_account_name
  storage_account_access_key             = module.storage.storage_account_primary_key
  application_insights_key               = module.observability.application_insights_instrumentation_key
  application_insights_connection_string = module.observability.application_insights_connection_string
  key_vault_id                          = module.security.key_vault_id
  managed_identity_id                   = module.security.managed_identity_ids["function-apps-identity"]
  subnet_id                             = module.networking.subnet_ids.services
  
  # Private endpoint configuration
  private_endpoint_subnet_id  = module.networking.subnet_ids.services
  private_dns_zone_id         = module.networking.private_dns_zone_ids.functions
  
  # Function apps configuration (empty for now)
  function_apps            = []
  consumption_plan_enabled = true
  
  tags = local.tags
}

# AI Services Module
module "ai_services" {
  source = "./modules/ai-services"
  
  resource_group_name = azurerm_resource_group.shared_rg.name
  location           = azurerm_resource_group.shared_rg.location
  environment        = "demo"
  project_name       = local.prefix
  
  # Dependencies
  key_vault_id        = module.security.key_vault_id
  managed_identity_id = module.security.managed_identity_ids["ai-services-identity"]
  subnet_id          = module.networking.subnet_ids.services
  
  # AI services configuration
  openai_deployments = [
    {
      name     = "gpt-4"
      model    = "gpt-4"
      version  = "0613"
      capacity = 10
    },
    {
      name     = "gpt-35-turbo"
      model    = "gpt-35-turbo"
      version  = "0613"
      capacity = 10
    },
    {
      name     = "text-embedding-ada-002"
      model    = "text-embedding-ada-002"
      version  = "2"
      capacity = 10
    }
  ]
  
  form_recognizer_enabled    = true
  computer_vision_enabled    = false
  private_endpoints_enabled  = false
  
  tags = local.tags
}