// -----------------------------------------------------------------------------
// Network Resources
// -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "workload_vnet" {
  name                = "${local.prefix}"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  address_space       = [var.cidr]
  tags                = local.tags
}

resource "azurerm_network_security_group" "dmz_nsg" {
  name                = "${local.prefix}-dmz"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  tags                = local.tags
}

resource "azurerm_network_security_group" "compute_nsg" {
  name                = "${local.prefix}-compute"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  tags                = local.tags
}

// subnet for gateways with address of 10.0.0.0/24
resource "azurerm_subnet" "dmz" {
  name                 = "dmz"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 0)]
}
resource "azurerm_subnet_network_security_group_association" "nsg_dmz" {
  subnet_id                 = azurerm_subnet.dmz.id
  network_security_group_id = azurerm_network_security_group.dmz_nsg.id
}

// subnet for PaaS services with address of 10.0.1.0/24
resource "azurerm_subnet" "services" {
  name                 = "services"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 1)]

}
resource "azurerm_subnet_network_security_group_association" "nsg_services" {
  subnet_id                 = azurerm_subnet.services.id
  network_security_group_id = azurerm_network_security_group.compute_nsg.id
}

// subnet for function apps with address of 10.0.2.0/24
resource "azurerm_subnet" "function_apps" {
  name                 = "functionapps"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 2)]

  delegation {
    name = "function-apps-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
resource "azurerm_subnet_network_security_group_association" "nsg_function_apps" {
  subnet_id                 = azurerm_subnet.function_apps.id
  network_security_group_id = azurerm_network_security_group.compute_nsg.id
}

// subnet for virtual machines (utility VMs) with address of 10.0.3.0/24
resource "azurerm_subnet" "utility_vms" {
  name                  = "utility"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  virtual_network_name  = azurerm_virtual_network.workload_vnet.name
  address_prefixes      = [cidrsubnet(var.cidr, 8, 3)]
}

// subnet for container apps with address of 10.0.4.0/23 (10.0..4.0 - 10.0.5.255)
resource "azurerm_subnet" "container_apps" {
  name                 = "containerapps"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 7, 4)]
}
resource "azurerm_subnet_network_security_group_association" "nsg_container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.compute_nsg.id
}



// DNS Zones for Private Endpoints

// Private DNS zone for Storage Account Blob service
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_dns_zone_link" {
  name                  = "${local.prefix}-blob-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}

// Private DNS zone for Container Registry
resource "azurerm_private_dns_zone" "container_registry" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "container_registry_dns_zone_link" {
  name                  = "${local.prefix}-container-registry-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.container_registry.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}

// Private DNS zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_dns_zone_link" {
  name                  = "${local.prefix}-keyvault-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}

// Private DNS zone for Function Apps
resource "azurerm_private_dns_zone" "functions" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "functions_dns_zone_link" {
  name                  = "${local.prefix}-functions-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.functions.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}

// Private DNS zone for Container Apps
resource "azurerm_private_dns_zone" "container_app" {
  name                = "privatelink.${var.region}.containerapps.azure.io"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "container_app_dns_zone_link" {
  name                  = "${local.prefix}-container-apps-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.container_app.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}

// Private DNS zone for Cosmos DB
resource "azurerm_private_dns_zone" "cosmos_db" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_db_dns_zone_link" {
  name                  = "${local.prefix}-cosmosdb-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_db.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}

// Private DNS zone for Cognitive Services (Document Intelligence, AI Foundry, etc.)
resource "azurerm_private_dns_zone" "cognitive_services" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = azurerm_resource_group.shared_rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "cognitive_services_dns_zone_link" {
  name                  = "${local.prefix}-cognitiveservices-dns-link"
  resource_group_name   = azurerm_resource_group.shared_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cognitive_services.name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
}


// -----------------------------------------------------------------------------
// Application Identities
// -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "invoiceapi_identity" {
  name                = "${local.prefix}-invoiceapi-identity"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
}

// This is the identity to be used by the function app to access other resources
resource "azurerm_user_assigned_identity" "func_mcp_identity" {
  name                = "${local.prefix}-funcapp-identity"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
}

// container app user assigned identity for pulling container images
resource "azurerm_user_assigned_identity" "containerapp_acr_identity" {
  name                = "${local.prefix}-containerapp-acr-identity"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
}


// -----------------------------------------------------------------------------
// Observability Resources
// -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "invoiceapi" {
  name                = "${local.prefix}-log-analytics"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "invoiceapi" {
  name                = "${local.prefix}-appinsights"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  workspace_id        = azurerm_log_analytics_workspace.invoiceapi.id
  application_type    = "web"
}


// -----------------------------------------------------------------------------
// Application Secrets
// -----------------------------------------------------------------------------

resource "azurerm_key_vault" "invoiceapi_secrets" {
  name                     = "${local.prefix}-kv"
  location                 = azurerm_resource_group.shared_rg.location
  resource_group_name      = azurerm_resource_group.shared_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  enabled_for_disk_encryption = true
  public_network_access_enabled = false
  tags                     = local.tags
}
resource "azurerm_private_endpoint" "invoice_api_secrets_pe" {
  name                = "${local.prefix}-kv-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.keyvault_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.invoiceapi_secrets.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "key-vault-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.keyvault.id ]
  }
}

/*
resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id       = azurerm_key_vault.this.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["Delete", "Get", "List", "Set","Recover"]
}

resource "azurerm_key_vault_secret" "invoiceapi_secret_akv" {
    name         = "invoiceapi-secret-${data.azurerm_client_config.current.tenant_id}"
    value        = "test secret from AKV"
    key_vault_id = azurerm_key_vault.this.id
    depends_on = [ azurerm_key_vault_access_policy.this ]
}
*/


// -----------------------------------------------------------------------------
// API Storage
// -----------------------------------------------------------------------------

resource "azurerm_storage_account" "invoiceapi_storage" {
  name                     = "${local.identifier}invapistorage"
  resource_group_name      = azurerm_resource_group.shared_rg.name
  location                 = azurerm_resource_group.shared_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled  = true
  tags                     = local.tags
}
resource "azurerm_private_endpoint" "storage_account" {
  name                = "${local.prefix}-invapistorage-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.storage_blob_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-invapistorage-psc"
    private_connection_resource_id = azurerm_storage_account.invoiceapi_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "api-storage-blob-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.storage_blob.id ]
  }
}

resource "azurerm_storage_container" "invoices_container" {
  name                  = "invoices"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "images_container" {
  name                  = "images"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "docintel_container" {
  name                  = "docintel"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "markdown_container" {
  name                  = "markdown"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "annotation_container" {
  name                  = "annotations"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "xml_container" {
  name                  = "xml"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "results_container" {
  name                  = "results"
  storage_account_id    = azurerm_storage_account.invoiceapi_storage.id
  container_access_type = "private"
}

// add current authenticated user as blob storage contributor
resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.invoiceapi_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

// Function App Storage Account

resource "azurerm_storage_account" "func_storage" {
  name                     = "${local.identifier}funcstorage"
  resource_group_name      = azurerm_resource_group.shared_rg.name
  location                 = azurerm_resource_group.shared_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled  = true
  shared_access_key_enabled = false
  public_network_access_enabled = false
  tags                     = local.tags
}

resource "azurerm_private_endpoint" "funcapp_storage_account" {
  name                = "${local.prefix}-funcappstorage-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.storage_blob_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-funcappstorage-psc"
    private_connection_resource_id = azurerm_storage_account.func_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "funcapp-storage-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.storage_blob.id ]
  }
}

// Grant current user blob storage contributor to function app storage account
resource "azurerm_role_assignment" "deployer_funcappstorage_blob_contributor" {
  scope                = azurerm_storage_account.func_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}


// -----------------------------------------------------------------------------
// Cosmos DB
// -----------------------------------------------------------------------------

resource "azurerm_cosmosdb_account" "invoiceapi_cosmosdb" {
  name                = "${local.identifier}-cosmosdb"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level       = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.shared_rg.location
    failover_priority = 0
  }
  capabilities {
    name = "EnableServerless"
  }
  tags = local.tags
}

resource "azurerm_cosmosdb_sql_database" "invoiceapi_database" {
  name                = "invoiceapi-db"
  resource_group_name = azurerm_resource_group.shared_rg.name
  account_name       = azurerm_cosmosdb_account.invoiceapi_cosmosdb.name
}

resource "azurerm_cosmosdb_sql_container" "invoiceapi_container" {
  name                = "invoices"
  resource_group_name = azurerm_resource_group.shared_rg.name
  account_name       = azurerm_cosmosdb_account.invoiceapi_cosmosdb.name
  database_name      = azurerm_cosmosdb_sql_database.invoiceapi_database.name
  partition_key_paths = ["/invoiceId"]
  partition_key_version = 2
}

resource "azurerm_private_endpoint" "cosmosdb_account" {
  name                = "${local.prefix}-cosmosdb-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.cosmos_db_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-cosmosdb-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.invoiceapi_cosmosdb.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "cosmosdb-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.cosmos_db.id ]
  }
}


// -----------------------------------------------------------------------------
// Document Intelligence Account
// -----------------------------------------------------------------------------

resource "azurerm_cognitive_account" "invoiceapi_docintel" {
  name                = "${local.identifier}-docintel"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  sku_name            = "S0"
  tags                = local.tags
  kind                = "FormRecognizer"
  identity {
    type = "SystemAssigned"
  }
  public_network_access_enabled = false
  custom_subdomain_name = "${local.identifier}"
}

// document intelligence private endpoint
resource "azurerm_private_endpoint" "docintel_account" {
  name                = "${local.prefix}-docintel-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  private_service_connection {
    name                           = "${local.prefix}-docintel-psc"
    private_connection_resource_id = azurerm_cognitive_account.invoiceapi_docintel.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "docintel-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.cognitive_services.id ]
  }
}


// -----------------------------------------------------------------------------
// Azure AI Foundry
// -----------------------------------------------------------------------------

resource "azapi_resource" "ai_foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = "${local.identifier}-aifoundry"
  parent_id                 = azurerm_resource_group.shared_rg.id
  location                  = var.region_aifoundry
  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      # Support both Entra ID and API Key authentication for Cognitive Services account
      disableLocalAuth = false

      # Specifies that this is an AI Foundry resourceyes
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = "${local.identifier}"
    }
  }
}


resource "azapi_resource" "aifoundry_deployment_gpt41mini" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2023-05-01"
  name      = "gpt-41-mini"
  parent_id = azapi_resource.ai_foundry.id
  depends_on = [
    azapi_resource.ai_foundry
  ]

  body = {
    sku = {
      name     = "GlobalStandard"
      capacity = 1
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1-mini"
        version = "2025-04-14"
      }
    }
  }
}

resource "azapi_resource" "aifoundry_deployment_gpt41" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2023-05-01"
  name      = "gpt-41"
  parent_id = azapi_resource.ai_foundry.id
  depends_on = [
    azapi_resource.ai_foundry
  ]

  body = {
    sku = {
      name     = "GlobalStandard"
      capacity = 1
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = "gpt-4.1"
        version = "2025-04-14"
      }
    }
  }
}

resource "azapi_resource" "ai_foundry_project" {
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = "${local.identifier}-project"
  parent_id                 = azapi_resource.ai_foundry.id
  location                  = var.region_aifoundry
  schema_validation_enabled = false

  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      displayName = "project"
      description = "Invoice AI Project"
    }
  }
}

// -----------------------------------------------------------------------------
// Container Registry
// -----------------------------------------------------------------------------

resource "azurerm_container_registry" "invoiceapi" {
  name                = "${local.identifier}invoiceapi"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  sku                 = "Premium"
  tags                = local.tags
  admin_enabled                   = false
  anonymous_pull_enabled          = false
  public_network_access_enabled   = false

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "container_registry" {
  name                = "${local.prefix}-acr-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.container_registry_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.invoiceapi.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "container-registry-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.container_registry.id]
  }
}

// grant the current user ability to push images to the container registry
resource "azurerm_role_assignment" "deployer_acr_push_role_assignment" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "AcrPush"
  scope                = azurerm_container_registry.invoiceapi.id
}

// grant the container registry pull role to the container app identity
resource "azurerm_role_assignment" "acr_pull_role_assignment_containerapp" {
  principal_id                     = azurerm_user_assigned_identity.containerapp_acr_identity.principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.invoiceapi.id
  skip_service_principal_aad_check = true
}

// run an az cli command to provision a repository in the container registry
resource "null_resource" "acr_repository_setup" {
  provisioner "local-exec" {
    command = "az acr import --name ${azurerm_container_registry.invoiceapi.name} --source mcr.microsoft.com/mcr/hello-world:latest --image hello-world:latest"
  }
  depends_on = [ azurerm_container_registry.invoiceapi ]
}


// -----------------------------------------------------------------------------
// Container Apps Environment
// -----------------------------------------------------------------------------

resource "azurerm_container_app_environment" "finance_apps" {
  name                = "${local.prefix}-containerapp-env"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.invoiceapi.id
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }

  infrastructure_subnet_id = azurerm_subnet.container_apps.id
  public_network_access = "Disabled"
}

// private endpoint for container apps environment
resource "azurerm_private_endpoint" "container_apps_environment" {
  name                = "${local.prefix}-containerapp-env-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.container_app_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-containerapp-env-psc"
    private_connection_resource_id = azurerm_container_app_environment.finance_apps.id
    subresource_names              = ["managedEnvironments"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "container-apps-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.container_app.id ]
  }
}

// sample container app deployment (hello world)
resource "azurerm_container_app" "hello_world" {
  name                         = "hello-world"
  container_app_environment_id = azurerm_container_app_environment.finance_apps.id
  resource_group_name          = azurerm_resource_group.shared_rg.name
  revision_mode                = "Single"
  tags = local.tags
  depends_on = [ null_resource.acr_repository_setup, azurerm_role_assignment.acr_pull_role_assignment_containerapp ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp_acr_identity.id]
  }
  
  template {
    container {
      name   = "examplecontainerapp"
      image  = "${azurerm_container_registry.invoiceapi.login_server}/hello-world:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    /*
    custom_scale_rule {
      name                = "http-scale-rule"
      custom_rule_type    = "http"
      metadata = {
        concurrentRequests = "50"
      }
    }
    */
  }
  
  /*
  ingress {
    allow_insecure_connections = false
    target_port = 443
    traffic_weight {
      label = "production"
      percentage = 100
    }
  }
  */

  registry {
    identity = azurerm_user_assigned_identity.containerapp_acr_identity.id
    server   = azurerm_container_registry.invoiceapi.login_server
  }

}


// -----------------------------------------------------------------------------
// Function Apps
// -----------------------------------------------------------------------------

resource "azurerm_service_plan" "function_app_plan" {
  name                = "mcp-function-app-service-plan"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  os_type             = "Linux"
  sku_name            = "EP1"
}

resource "azurerm_linux_function_app" "mcp" {
  name                        = "${local.prefix}-mcp"
  resource_group_name         = azurerm_resource_group.shared_rg.name
  location                    = azurerm_resource_group.shared_rg.location
  service_plan_id             = azurerm_service_plan.function_app_plan.id
  storage_account_name        = azurerm_storage_account.func_storage.name
  storage_uses_managed_identity = true
  # storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  identity {
    type = "SystemAssigned"
  }

  virtual_network_subnet_id = azurerm_subnet.function_apps.id
  public_network_access_enabled = false

  site_config {
    application_insights_connection_string = azurerm_application_insights.invoiceapi.connection_string
    application_insights_key = azurerm_application_insights.invoiceapi.instrumentation_key
    application_stack {
      python_version = "3.13"
    } 
    
  }
}

// Grant MCP function app blob storage contributor
resource "azurerm_role_assignment" "funcapp_storage_blob_contributor" {
  scope                = azurerm_storage_account.func_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.mcp.identity[0].principal_id
}

resource "azurerm_private_endpoint" "function_app" {
  name                = "${local.prefix}-funcapp-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.functions_dns_zone_link ]
  private_service_connection {
    name                           = "${local.prefix}-funcapp-psc"
    private_connection_resource_id = azurerm_linux_function_app.mcp.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name = "function-app-dns-zone-group"
    private_dns_zone_ids = [ azurerm_private_dns_zone.functions.id ]
  }
}


// -----------------------------------------------------------------------------
// Utility VM
// -----------------------------------------------------------------------------

resource "azurerm_network_interface" "utility_vm_nic" {
  name                = "${local.prefix}-utilityvm-nic"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.utility_vms.id
    private_ip_address_allocation = "Dynamic"
  }
}

// change this to a windows 11 image
resource "azurerm_windows_virtual_machine" "utility_vm" {
  name                = "${local.prefix}-util"
  computer_name       = "utilityvm"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  size                = "Standard_D4s_v3"
  admin_username      = "azureuser"
  admin_password = var.utility_vm_admin_password

  network_interface_ids = [
    azurerm_network_interface.utility_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-25h2-pro"
    version   = "latest"
  }

  tags = local.tags
}