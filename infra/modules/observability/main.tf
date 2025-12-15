# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "la_workspace" {
  name                = "${var.prefix}-law"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.prefix}-ai"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.la_workspace.id
  application_type    = "web"
  tags                = var.tags
  
  lifecycle {
    ignore_changes = [tags]
  }
}