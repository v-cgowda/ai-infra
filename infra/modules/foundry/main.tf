# Local values for conditional private endpoint creation
locals {
    model_deployments = {
    for model in var.model_deployments : model.name => model
  }
}

# Microsoft Foundry (OpenAI Service with Project Management)
resource "azapi_resource" "foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "${var.subdomain_name}-foundry-${var.environment}"
  parent_id                 = var.resource_group_id
  location                  = var.location
  schema_validation_enabled = false
  tags = merge(var.tags, {
    Module  = "ai-services"
    Service = "AIFoundry"
  })

  body = {
    kind = "AIServices"
    sku = {
      name = var.sku
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      disableLocalAuth       = var.disable_local_auth
      allowProjectManagement = true
      customSubDomainName    = var.subdomain_name
      publicNetworkAccess    = var.public_network_access
      restore                = true

      # see: https://github.com/microsoft/CAIRA/blob/4b942277f04ff0635496879c5eb05a0e8d547a2d/modules/ai_foundry/main.tf#L36
      networkAcls =  var.foundry_subnet_id != null ? {
        defaultAction = "Allow"
      } : null

      networkInjections = var.agents_subnet_id != null ? [
        {
          scenario                    = "agent"
          subnetArmId                 = var.agents_subnet_id
          useMicrosoftManagedNetwork  = false
        }
      ] : null
    }
  }
}

## Wait 60 seconds for the AI Foundry finishes creating before creating private endpoints
resource "time_sleep" "wait_ai_foundry" {
  depends_on = [
    azapi_resource.foundry
  ]
  create_duration = "60s"
}

# Private Endpoints for Foundry
resource "azurerm_private_endpoint" "foundry" {
  count               = length(var.dns_zone_ids) > 0 ? 1 : 0
  name                = "${var.subdomain_name}-foundry-${var.environment}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.foundry_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.subdomain_name}-foundry-${var.environment}-psc"
    private_connection_resource_id = azapi_resource.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
      name                 = "foundry-dns-zone-group"
      private_dns_zone_ids = var.dns_zone_ids
  }

  depends_on = [
    time_sleep.wait_ai_foundry
  ]

}

# Foundry Model Deployments
resource "azurerm_cognitive_deployment" "model_deployments" {
  for_each = local.model_deployments

  name                  = each.value.name
  cognitive_account_id  = azapi_resource.foundry.id
  
  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }

  model {
    format  = each.value.model.format
    name    = each.value.model.name
    version = each.value.model.version
  }

  depends_on = [
    azurerm_private_endpoint.foundry
  ]
}

# Foundry Projects
resource "azapi_resource" "foundry_project" {
  for_each = {
    for project in var.projects : project.name => project
  }

  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = each.value.name
  parent_id                 = azapi_resource.foundry.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    sku = {
      name = var.sku
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      displayName = each.value.display_name
      description = each.value.description
    }
  }
  depends_on = [
    azurerm_cognitive_deployment.model_deployments
  ]
}

# Application Insights
resource "azapi_resource" "foundry_appinsights_connection" {
  count                     = var.enable_app_insights_connection ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name                      = "${var.subdomain_name}-foundry-${var.environment}-appinsights-connection"
  parent_id                 = azapi_resource.foundry.id
  schema_validation_enabled = false
  depends_on                = [azapi_resource.foundry_project]

  body = {
    properties = {
      category      = "AppInsights"
      target        = var.app_insights_resource_id
      authType      = "ApiKey"
      isSharedToAll = true
      credentials = {
        key = var.app_insights_instrumentation_key
      }
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.app_insights_resource_id
      }
    }
  }
}
