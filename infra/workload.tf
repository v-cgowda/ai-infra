# Define Workload Infrastructure

##################################################
# Networking Module
##################################################

module "networking" {
  source              = "./modules/networking"
  prefix              = local.identifier
  resource_group_name = data.azurerm_resource_group.shared_rg.name
  location            = data.azurerm_resource_group.shared_rg.location
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
    AzureFirewallSubnet = {
      address_prefix = cidrsubnet(var.cidr, 10, 0) # 10.0.0.0/26 for firewall (10.0.0.0 - 10.0.0.63)
    }
    dmz = {
      address_prefix = cidrsubnet(var.cidr, 10, 1) # 10.0.0.64/26 for dmz (10.0.0.64 - 10.0.0.127)
      nsg_name       = "dmz"
    }
    services = {
      address_prefix = cidrsubnet(var.cidr, 8, 1)
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
      delegation = {
        name = "container-app-delegation"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }
    }
    foundry = {
      address_prefix = cidrsubnet(var.cidr, 8, 6)
      delegation = {
        name = "service-delegation-aifoundry"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
     }
    }
  }

  private_dns_zone_names = ["storage_blob", "container_registry", "keyvault", "functions", "container_apps", "cosmosdb", "cognitive_services", "openai", "ai_services"]

}


##################################################
# Observability Module
##################################################

module "observability" {
  source = "./modules/observability"
  prefix              = local.identifier
  resource_group_name = data.azurerm_resource_group.shared_rg.name
  location            = data.azurerm_resource_group.shared_rg.location
  tags                = local.tags
}


##################################################
# Security Module
##################################################

module "security" {
  source                 = "./modules/security"
  prefix                 = local.identifier
  resource_group_name    = data.azurerm_resource_group.shared_rg.name
  location               = data.azurerm_resource_group.shared_rg.location
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
    resource_group_name           = data.azurerm_resource_group.shared_rg.name
    location                      = data.azurerm_resource_group.shared_rg.location
    sku                           = "Premium"
    environment                   = "demo"
    project_name                  = local.identifier
    public_network_access_enabled = false
    anonymous_pull_enabled        = false
    enable_private_endpoints = true
    private_endpoint_info = {
      subnet_id   = module.networking.subnet_ids["services"]
      dns_zone_id = module.networking.private_dns_zone_ids["container_registry"]
    }
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
# Storage Module (application storage)
##################################################

module "app_storage" {
  source                = "./modules/storage"
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  location              = data.azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.identifier

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
  enable_private_endpoints    = true
  private_endpoint_subnet_id  = module.networking.subnet_ids["services"]
  private_dns_zone_ids = {
    blob = module.networking.private_dns_zone_ids["storage_blob"]
  }

  tags = local.tags
}


##################################################
# Storage Module (function app storage)
##################################################

module "funcapp_storage" {
  source                = "./modules/storage"
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  location              = data.azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = "${local.identifier}funcapp"

  # Storage configuration
  storage_account_tier          = "Standard"
  storage_account_replication   = "LRS"
  enable_versioning             = true
  enable_soft_delete            = true
  shared_access_key_enabled     = false

  # Private endpoint configuration
  enable_private_endpoints      = true
  private_endpoint_subnet_id    = module.networking.subnet_ids["services"]
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
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  location              = data.azurerm_resource_group.shared_rg.location
  environment           = "dev"
  project_name          = local.identifier
  depends_on            = [ terraform_data.acr_repository_provision_hello_world_api ]
  tags = local.tags

  # Dependencies
  subnet_id                           = module.networking.subnet_ids["containerapps"]
  log_analytics_workspace_id          = module.observability.log_analytics_workspace_id
  container_registry_id               = module.container_registry.id
  container_registry_login_server     = module.container_registry.login_server
  managed_identity_id                 = module.security.managed_identity_ids["containerapp-identity"]

  # Private endpoint configuration
  enable_private_endpoints = true
  private_endpoint_info = {
    subnet_id   = module.networking.subnet_ids["services"]
    dns_zone_id = module.networking.private_dns_zone_ids["container_apps"]
  }

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
      image                  = "${module.container_registry.login_server}/hello-world-api:latest"
      cpu                    = 0.5
      memory                 = "1.0Gi"
      replicas               = 2
      min_replicas           = 1
      max_replicas           = 3
      external_ingress       = true
      workload_profile_name  = ""
      target_port            = 8000
      workload_profile_name  = "internal-small"
      env_vars               = [ ]
      secrets                = [ ]
    }
  ]
  dapr_enabled   = false
}


##################################################
# Function Apps
##################################################

module "function_apps" {
  source                = "./modules/function-apps"
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  location              = data.azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.identifier
  service_plan_sku      = "EP1"
  tags = local.tags

  # Dependencies
  storage_account_name                      = module.funcapp_storage.storage_account_name
  application_insights_key                  = module.observability.application_insights_instrumentation_key
  application_insights_connection_string    = module.observability.application_insights_connection_string
  key_vault_id                              = module.security.key_vault_id
  enable_system_assigned_identity           = true
  subnet_id                                 = module.networking.subnet_ids["functionapps"]

  # Private endpoint configuration
  enable_private_endpoints = true
  private_endpoint_subnet_id  = module.networking.subnet_ids["services"]
  private_dns_zone_id         = module.networking.private_dns_zone_ids["functions"]

  # Function apps configuration (empty for now)
  function_apps            = [
    {
      name                   = "${local.identifier}-echo"
      runtime_stack          = "python" # "python", "node", "dotnet", "java"
      runtime_version        = "3.13"
      always_on              = true
      app_settings           = {}
      connection_strings     = {}
      enable_vnet_integration = true
    }
  ]
}


##################################################
# AI Services Module
##################################################

module "ai_services" {
  source                = "./modules/ai-services"
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  location              = data.azurerm_resource_group.shared_rg.location
  environment           = "demo"
  project_name          = local.identifier

  form_recognizer_enabled    = true
  computer_vision_enabled    = false

  enable_private_endpoints = true
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
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  resource_group_id     = data.azurerm_resource_group.shared_rg.id
  location              = var.region_aifoundry
  subdomain_name        = local.identifier
  environment           = "demo"
  tags                  = local.tags

  # networking - VNET injection for agents
  agents_subnet_id    = module.networking.subnet_ids["foundry"]

  # networking - private endpoint
  foundry_subnet_id   = module.networking.subnet_ids["services"]
  dns_zone_ids = [
    module.networking.private_dns_zone_ids["cognitive_services"],
    module.networking.private_dns_zone_ids["openai"],
    module.networking.private_dns_zone_ids["ai_services"]
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


  model_deployments = [
    {
      name     = "demo-gpt-41-mini"
      sku_name = "GlobalStandard"
      capacity = 1
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1-mini"
        version = "2025-04-14"
      }
    },
    {
      name     = "demo-gpt-41"
      sku_name = "GlobalStandard"
      capacity = 1
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
    }
  ]

  enable_app_insights_connection = true
  app_insights_resource_id = module.observability.application_insights_id
  app_insights_instrumentation_key = module.observability.application_insights_instrumentation_key
}


##################################################
# Virtual Machine Module (Utility VM)
##################################################

module "utility_vm" {
  source                = "./modules/virtual-machines"
  resource_group_name   = data.azurerm_resource_group.shared_rg.name
  location              = data.azurerm_resource_group.shared_rg.location
  prefix                = local.identifier
  computer_name         = "${local.identifier}-util"
  
  # Networking
  subnet_id             = module.networking.subnet_ids["utility"]
  
  # VM Configuration
  vm_size               = "Standard_D4s_v3"
  admin_username        = "azureuser"
  admin_password        = var.utility_vm_admin_password

  # Pass the script content to be executed via Custom Script Extension
  # work in progress - commented out for now
  # setup_script          = templatefile("${path.module}/scripts/util_vm_setup.ps1", {})
  # setup_script_name     = "util_vm_setup.ps1"
  
  tags = local.tags
}


##################################################
# Azure Bastion
##################################################

module "bastion" {
  source                  = "./modules/bastion"
  prefix                  = local.identifier
  resource_group_name     = data.azurerm_resource_group.shared_rg.name
  location                = data.azurerm_resource_group.shared_rg.location
  virtual_network_name    = module.networking.virtual_network_name
  subnet_address_prefix   = cidrsubnet(var.cidr, 10, 2) # 10.0.0.128/26 for bastion (10.0.0.128 - 10.0.0.191)
  sku                     = "Basic" # "Basic", "Standard", "Developer"
  copy_paste_enabled      = true
  enable_tunneling        = true
  enable_ip_connect       = true
  enable_shareable_link   = true
  enable_file_copy        = true
  tags                    = local.tags
}

##################################################
# Permissions
##################################################

// add current authenticated user as blob storage contributor to the app storage account
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = module.app_storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

// add the System Assigned managed identity for the first Function App blob storage contributor to its storage account
resource "azurerm_role_assignment" "funcapp_storage_blob_contributor" {
  scope                = module.funcapp_storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.function_apps.function_app_identities["0"]
}

// grant the current user ability to push images to the container registry
resource "azurerm_role_assignment" "acr_push_current_user" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

// grant the Function App managed identity pull access to the container registry
resource "azurerm_role_assignment" "acr_pull_funcapp_identity" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = module.security.managed_identity_principal_ids["funcapp-identity"]
}

// grant the Container App managed identity pull access to the container registry
resource "azurerm_role_assignment" "acr_pull_containerapp_identity" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = module.security.managed_identity_principal_ids["containerapp-identity"]
}


##################################################
# Script - run an az cli command to provision a repository in the container registry
##################################################

resource "terraform_data" "acr_repository_provision_hello_world_api" {
  provisioner "local-exec" {
    command = "az acr import --name ${module.container_registry.name} --source docker.io/trniel/hello-world-api:latest --image hello-world-api:latest || echo 'Image already exists, skipping import'"
  }
  depends_on = [ module.container_registry ]
}


##################################################
# Script - deploy code to function app from local directory
################################################## 

# Public IP access is required for function app deployment

/*
resource "archive_file" "function_app_code" {
  type        = "zip"
  source_dir  = "${path.module}/../function-app"
  output_path = "${path.module}/function-app.zip"
}

resource "terraform_data" "function_app_deploy_code" {
  provisioner "local-exec" {
    command = <<EOT
      az functionapp deployment source config-zip \
        --resource-group ${azurerm_resource_group.shared_rg.name} \
        --name ${module.function_apps.function_apps[0].name} \
        --src ${path.module}/function-app.zip
    EOT
  }
  triggers_replace = {
    code_hash = archive_file.function_app_code.output_base64sha256
  }
  depends_on = [ module.function_apps, archive_file.function_app_code]
}
*/