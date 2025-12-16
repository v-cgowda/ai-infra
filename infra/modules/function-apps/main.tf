# Service Plans for Function Apps
resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.project_name}-app-service-plan-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.service_plan_sku

  tags = merge(var.tags, {
    Module = "function-apps"
  })
}

# Function Apps
resource "azurerm_linux_function_app" "apps" {
  for_each = {
    for idx, app in var.function_apps : tostring(idx) => app
  }

  name                = "${each.value.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  service_plan_id           = azurerm_service_plan.app_service_plan.id

  # function app storage
  storage_account_name       = var.storage_account_name
  storage_uses_managed_identity = var.storage_account_access_key == "" ? true : false
  storage_account_access_key = var.storage_account_access_key != "" ? var.storage_account_access_key : null
  

  # Identity configuration
  identity {
    type         = var.enable_system_assigned_identity ? "SystemAssigned" : (var.managed_identity_id != "" ? "UserAssigned" : "SystemAssigned")
    identity_ids = var.enable_system_assigned_identity ? null : (var.managed_identity_id != "" ? [var.managed_identity_id] : null)
  }

  # networking
  virtual_network_subnet_id = var.subnet_id != "" ? var.subnet_id : null
  public_network_access_enabled = var.public_access_enabled

  # Site configuration
  site_config {
    always_on = each.value.always_on

    application_stack {
      python_version = each.value.runtime_stack == "python" ? each.value.runtime_version : null
      node_version   = each.value.runtime_stack == "node" ? each.value.runtime_version : null
      dotnet_version = each.value.runtime_stack == "dotnet" ? each.value.runtime_version : null
      java_version   = each.value.runtime_stack == "java" ? each.value.runtime_version : null
    }

    # CORS configuration
    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }

    # Application Insights
    application_insights_key               = var.application_insights_key
    application_insights_connection_string = var.application_insights_connection_string
  }

  # App settings
  app_settings = merge(
    {
      "FUNCTIONS_EXTENSION_VERSION"              = "~4"
      "FUNCTIONS_WORKER_RUNTIME"                 = each.value.runtime_stack
      "WEBSITE_RUN_FROM_PACKAGE"                 = "1"
      "APPINSIGHTS_INSTRUMENTATIONKEY"           = var.application_insights_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING"    = var.application_insights_connection_string
    },
    var.storage_account_access_key != "" ? {
      "AzureWebJobsStorage" = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};AccountKey=${var.storage_account_access_key};EndpointSuffix=core.windows.net"
    } : {},
    each.value.app_settings
  )

  # Connection strings
  dynamic "connection_string" {
    for_each = each.value.connection_strings
    content {
      name  = connection_string.key
      type  = "Custom"
      value = connection_string.value
    }
  }

  tags = merge(var.tags, {
    Module  = "function-apps"
    App     = each.value.name
    Runtime = each.value.runtime_stack
  })
}

# VNet Integration for Function Apps
/*
resource "azurerm_app_service_virtual_network_swift_connection" "vnet" {
  for_each = {
    for app in var.function_apps : app.name => app
    if app.enable_vnet_integration && var.subnet_id != ""
  }

  app_service_id = azurerm_linux_function_app.apps[each.key].id
  subnet_id      = var.subnet_id
}
*/

# Private Endpoints for Function Apps
resource "azurerm_private_endpoint" "function_app_pe" {
  for_each = var.enable_private_endpoints ? {
    for idx, app in var.function_apps : tostring(idx) => app
  } : {}

  name                = "${azurerm_linux_function_app.apps[each.key].name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_linux_function_app.apps[each.key].name}-psc"
    private_connection_resource_id = azurerm_linux_function_app.apps[each.key].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "function-app-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = merge(var.tags, {
    Module = "function-apps"
    App    = each.key
  })
}

/*
# To be considered at a future point: Source Control for Function Apps

resource "azurerm_app_service_source_control" "function_app_source_control" {
  for_each = {
    for idx, app in var.function_apps : tostring(idx) => app
    if app.source_control != null
  }

  app_id            = azurerm_linux_function_app.apps[each.key].id
  repo_url         = each.value.source_control.repo_url
  branch           = each.value.source_control.branch
  provider = ""
  use_manual_integration = each.value.source_control.use_manual_integration
  rollback_enabled = each.value.source_control.rollback_enabled
}
*/