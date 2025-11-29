# Cosmos Module Outputs

output "cosmos_account" {
  description = "Cosmos DB account information"
  value = {
    id                = azurerm_cosmosdb_account.cosmos.id
    name              = azurerm_cosmosdb_account.cosmos.name
    endpoint          = azurerm_cosmosdb_account.cosmos.endpoint
    primary_key       = azurerm_cosmosdb_account.cosmos.primary_key
    connection_string = azurerm_cosmosdb_account.cosmos.connection_strings[0]
  }
  sensitive = true
}

output "databases" {
  description = "Cosmos DB SQL databases"
  value = {
    for name, db in azurerm_cosmosdb_sql_database.database : name => {
      id   = db.id
      name = db.name
    }
  }
}

output "containers" {
  description = "Cosmos DB SQL containers"
  value = {
    for name, container in azurerm_cosmosdb_sql_container.container : name => {
      id   = container.id
      name = container.name
    }
  }
}

output "private_endpoint_id" {
  description = "Private endpoint ID"
  value       = length(azurerm_private_endpoint.cosmos) > 0 ? azurerm_private_endpoint.cosmos[0].id : null
}
