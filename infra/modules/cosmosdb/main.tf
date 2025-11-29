# Cosmos DB Account
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${var.project_name}-cosmosdb-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.offer_type
  kind                = var.kind

  public_network_access_enabled = var.public_network_access_enabled

  consistency_policy {
    consistency_level = var.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  tags = var.tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "database" {
  for_each = {
    for db in var.databases : db.name => db
  }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

# Cosmos DB SQL Containers
resource "azurerm_cosmosdb_sql_container" "container" {
  for_each = {
    for container in var.containers : "${container.database_name}-${container.name}" => container
  }

  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.cosmos.name
  database_name         = each.value.database_name
  partition_key_paths   = each.value.partition_key_paths
  partition_key_version = each.value.partition_key_version

  depends_on = [azurerm_cosmosdb_sql_database.database]
}

# Private Endpoint for Cosmos DB
resource "azurerm_private_endpoint" "cosmos" {
  count               = var.private_endpoint_info.subnet_id != "" ? 1 : 0
  name                = "${var.project_name}-cosmosdb-${var.environment}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_info.subnet_id

  private_service_connection {
    name                           = "${var.project_name}-cosmosdb-${var.environment}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint_info.dns_zone_id != "" ? [1] : []
    content {
      name                 = "cosmosdb-dns-zone-group"
      private_dns_zone_ids = [var.private_endpoint_info.dns_zone_id]
    }
  }

  tags = var.tags
}
