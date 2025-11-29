# Microsoft Foundry (OpenAI Service with Project Management)
resource "azapi_resource" "foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "${var.project_name}-foundry-${var.environment}"
  parent_id                 = var.resource_group_id
  location                  = var.location
  schema_validation_enabled = false

  body = jsonencode({
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
      customSubDomainName    = "${var.project_identifier}}"
      publicNetworkAccess    = var.public_network_access
      networkAcls = {
        defaultAction = var.network_restrictions.default_action
        
      }
      networkInjections = [
        {
          scenario = "agent"
          subnetArmId = var.vnet_integration_subnet_id != "" ? var.vnet_integration_subnet_id : null
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  })

  tags = merge(var.tags, {
    Module  = "ai-services"
    Service = "AIFoundry"
  })
}

# Foundry Model Deployments
resource "azapi_resource" "foundry_deployments" {
  for_each = {
    for deployment in var.model_deployments : deployment.name => deployment
  }

  type       = "Microsoft.CognitiveServices/accounts/deployments@2023-05-01"
  name       = each.value.name
  parent_id  = azapi_resource.foundry.id
  depends_on = [azapi_resource.foundry]

  body = jsonencode({
    sku = {
      name     = each.value.sku_name
      capacity = each.value.capacity
    }
    properties = {
      model = {
        format  = each.value.model.format
        name    = each.value.model.name
        version = each.value.model.version
      }
    }
  })
}

# Private Endpoints for Foundry
resource "azurerm_private_endpoint" "foundry" {
  count               = var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = "${var.project_name}-foundry-${var.environment}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-foundry-${var.environment}-psc"
    private_connection_resource_id = azapi_resource.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids["cognitiveServices"] != "" || var.private_dns_zone_ids["azureOpenAI"] != "" || var.private_dns_zone_ids["servicesAiAzure"] != "" ? [1] : []
    content {
      name                 = "foundry-dns-zone-group"
      private_dns_zone_ids = [for k, v in var.private_dns_zone_ids : v if v != ""]
    }
  }

  tags = merge(var.tags, {
    Module = "ai-services"
  })
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

  body = jsonencode({
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
  })
}

# Application Insights
resource "azapi_resource" "foundry_appinsights_connection" {
  count                     = var.app_insights_resource_id != "" && var.app_insights_instrumentation_key != "" ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name                      = "${azapi_resource.foundry.name}-appinsights-connection"
  parent_id                 = azapi_resource.foundry.id
  schema_validation_enabled = false
  depends_on                = [azapi_resource.foundry]

  body = jsonencode({
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
  })
}
