# Container Registry (keeping this here as it's referenced by the GitHub runner)
resource "azurerm_container_registry" "registry" {
  name                     = "${var.project_name}-acr-${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.sku
  admin_enabled            = false
  public_network_access_enabled = var.public_network_access_enabled
  anonymous_pull_enabled          = var.anonymous_pull_enabled

  identity {
    type = "SystemAssigned"
  }

  tags                     = var.tags
}

# Private Endpoint
resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = "${azurerm_container_registry.registry.name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${azurerm_container_registry.registry.name}-psc"
    private_connection_resource_id = azurerm_container_registry.registry.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "acr-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}