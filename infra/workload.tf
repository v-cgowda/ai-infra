# Define Workload Infrastructure

##################################################
# Networking Module
##################################################
module "networking" {
  source              = "./modules/networking"
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
    firewall = {
      address_prefix = cidrsubnet(var.cidr, 10, 0) # 10.0.0.0/26 for firewall (10.0.0.0 - 10.0.0.63)
      nsg_name       = "AzureFirewallSubnet"
    }  
    dmz = {
      address_prefix = cidrsubnet(var.cidr, 10, 1) # 10.0.0.64/26 for dmz (10.0.0.64 - 10.0.0.127)
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
    foundry = {
      address_prefix = cidrsubnet(var.cidr, 8, 6)
      nsg_name       = "compute"
    }
  }

  private_dns_zone_names = ["storage_blob", "container_registry", "keyvault", "functions", "container_apps", "cosmosdb", "cognitive_services", "openai", "ai_services"]

}

##################################################
# Observability Module
##################################################
module "observability" {
  source = "./modules/observability"
  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  tags                = local.tags
}

##################################################
# Security Module
##################################################
module "security" {
  source                 = "./modules/security"
  prefix                 = local.prefix
  resource_group_name    = azurerm_resource_group.shared_rg.name
  location               = azurerm_resource_group.shared_rg.location
  tenant_id              = data.azurerm_client_config.current.tenant_id
  current_user_object_id = data.azurerm_client_config.current.object_id
  subnet_id              = module.networking.subnet_ids["services"]
  private_dns_zone_id    = module.networking.private_dns_zone_ids["keyvault"]

  managed_identities = [
    { name = "funcapp-identity", description = "Identity for function apps for access to Container Registry" },
    { name = "containerapp-identity", description = "Identity for container apps for access to Container Registry" },
    { name = "github-runner-identity", description = "Identity for the GitHub runner" }
  ]

  tags                          = local.tags
}

##################################################
# Container Registry
##################################################
module "container_registry" {
    source                        = "./modules/container-registry"
    resource_group_name           = azurerm_resource_group.shared_rg.name
    location                      = azurerm_resource_group.shared_rg.location
    sku                           = "Standard"
    environment                   = "demo"
    project_name                  = local.prefix
    public_network_access_enabled = false
    anonymous_pull_enabled        = false
    private_endpoint_subnet_id    = module.networking.subnet_ids["services"]
    private_dns_zone_id           = module.networking.private_dns_zone_ids["container_registry"]
    tags                          = local.tags
}

##################################################
# GitHub Runner Module
##################################################
/*
module "github_runner" {
  source                        = "./modules/github-runner"
  prefix                        = local.prefix
  resource_group_name           = azurerm_resource_group.shared_rg.name
  location                      = azurerm_resource_group.shared_rg.location
  subnet_id                     = module.networking.subnet_ids["utility"]
  managed_identity_id           = module.security.managed_identity_ids["github-runner-identity"]
  managed_identity_principal_id = module.security.managed_identity_principal_ids["github-runner-identity"]
  subscription_id               = var.subscription_id
  container_registry_id         = module.container_registry.container_registry_id
  github_repository             = var.github_repository
  github_token                  = var.github_token
  ssh_public_key_path           = var.github_runner_ssh_public_key_path
  tags                          = local.tags
}
*/

##################################################
# Storage Module
##################################################
module "storage" {
  source                = "./modules/storage"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  location              = azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.prefix
  
  # Storage configuration
  storage_account_tier          = "Standard"
  storage_account_replication   = "LRS"
  enable_versioning             = true
  enable_soft_delete            = true
  
  containers = [
    {
      name   = "container-a"
      access = "private"
    },
    {
      name   = "container-b"
      access = "private"
    },
    {
      name   = "container-c"
      access = "private"
    }
  ]
  
  # Private endpoint configuration
  private_endpoint_subnet_id  = module.networking.subnet_ids["services"]
  private_dns_zone_ids = {
    blob = module.networking.private_dns_zone_ids["storage_blob"]
  }
  
  tags = local.tags
}

##################################################
# Container Apps Module
##################################################
module "container_apps" {
  source                = "./modules/container-apps"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  location              = azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.prefix
  
  # Dependencies
  subnet_id                    = module.networking.subnet_ids.containerapps
  log_analytics_workspace_id   = module.observability.log_analytics_workspace_id
  container_registry_id        = module.container_registry.container_registry_id
  container_registry_server    = module.container_registry.container_registry_login_server
  managed_identity_id          = module.security.managed_identity_ids["container-apps-identity"]
  
  # Private endpoint configuration
  private_endpoint_subnet_id  = module.networking.subnet_ids.services
  private_dns_zone_id         = module.networking.private_dns_zone_ids.container_apps

  # Workload profile configuration
  workload_profiles = [
    {
        name                  = "internal-small"
        workload_profile_type = "D4"
        maximum_count         = 10
        minimum_count         = 1
    }]
  
  # Container apps configuration
  container_apps = [
    {
      name                   = "hello-world-api"
      container_image        = "${module.container_registry.container_registry_login_server}/hello-world-api:latest"
      cpu                    = 0.5
      memory                 = "1.0Gi"
      replicas               = 2
      min_replicas           = 1
      max_replicas           = 3
      external_ingress       = true
      workload_profile_name  = ""
      target_port            = 8000
      workload_profile_name = "internal-small"

    }
  ]
  dapr_enabled   = false
  
  tags = local.tags
}

##################################################
# Function Apps Module
##################################################
module "function_apps" {
  source                = "./modules/function-apps"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  location              = azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.prefix
  
  # Dependencies
  storage_account_name                      = module.storage.storage_account_name
  storage_account_access_key                = module.storage.storage_account_primary_key
  application_insights_key                  = module.observability.application_insights_instrumentation_key
  application_insights_connection_string    = module.observability.application_insights_connection_string
  key_vault_id                              = module.security.key_vault_id
  managed_identity_id                       = module.security.managed_identity_ids["function-apps-identity"]
  subnet_id                                 = module.networking.subnet_ids.services
  
  # Private endpoint configuration
  private_endpoint_subnet_id  = module.networking.subnet_ids["services"]
  private_dns_zone_id         = module.networking.private_dns_zone_ids["functions"]
  
  # Function apps configuration (empty for now)
  function_apps            = [
    {
      name                   = "${local.prefix}-function-app"
      runtime_stack          = "python" # "python", "node", "dotnet", "java"
      runtime_version        = "3.13"
      always_on              = true
      app_settings           = {}
      connection_strings     = {}
      enable_vnet_integration = true
    }
  ]
  
  tags = local.tags
}

##################################################
# AI Services Module
##################################################
module "ai_services" {
  source                = "./modules/ai-services"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  location              = azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.prefix
  
  form_recognizer_enabled    = true
  computer_vision_enabled    = false

  private_endpoint_info = {
    subnet_id   = module.networking.subnet_ids["services"]
    dns_zone_id = module.networking.private_dns_zone_ids["cognitive_services"]
  }
  
  tags = local.tags
}

##################################################
# Foundry Module
##################################################
module "foundry" {
  source                = "./modules/foundry"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  resource_group_id     = azurerm_resource_group.shared_rg.id
  location              = azurerm_resource_group.shared_rg.location
  project_identifier    = local.prefix
  environment           = "demo"
  tags                  = local.tags

  # networking
  vnet_integration_subnet_id  = module.networking.subnet_ids["foundry"]
  private_endpoint_subnet_id  = module.networking.subnet_ids["services"]
  private_dns_zone_ids        = [ 
                                  module.networking.private_dns_zone_ids["ai_services"],
                                  module.networking.private_dns_zone_ids["cognitive_services"],
                                  module.networking.private_dns_zone_ids["openai"]
                                ]

  projects = [
    {
      name         = "project-1"
      display_name = "Foundry Project 1"
      description  = "This is the first Foundry project."
    },
    {
      name         = "project-2"
      display_name = "Foundry Project 2"
      description  = "This is the second Foundry project."
    }
  ]

  app_insights_resource_id = module.observability.application_insights_resource_id
  app_insights_instrumentation_key = module.observability.application_insights_instrumentation_key
}

##################################################
# Virtual Machine Module (Utility VM)
##################################################

module "utility_vm" {
  source                = "./modules/virtual-machines"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  location              = azurerm_resource_group.shared_rg.location
  prefix = local.prefix
  computer_name         = "${local.prefix}-util"
  
  # Networking
  subnet_id             = module.networking.subnet_ids["utility"]
  
  # VM Configuration
  vm_size               = "Standard_D4s_v3"
  admin_username        = "azureuser"
  admin_password = var.utility_vm_admin_password

  custom_data = base64encode(templatefile("${path.module}/scripts/util_vm_setup.ps1", {}))
  
  tags = local.tags
}