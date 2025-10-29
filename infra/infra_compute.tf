
// Key Vault

resource "azurerm_key_vault" "this" {
  name                     = "${local.prefix}-kv"
  location                 = azurerm_resource_group.shared_rg.location
  resource_group_name      = azurerm_resource_group.shared_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  enabled_for_disk_encryption = true
}

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

// Storage Account and Function App

resource "azurerm_storage_account" "func_storage" {
  name                     = "${local.identifier}funcstorage"
  resource_group_name      = azurerm_resource_group.shared_rg.name
  location                 = azurerm_resource_group.shared_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
 # enable_https_traffic_only = true
  tags                     = local.tags
}

resource "azurerm_private_endpoint" "func_storage_pe" {
  name                = "${local.prefix}-func-storage-pe"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  subnet_id           = azurerm_subnet.services.id
  depends_on = [ azurerm_private_dns_zone_virtual_network_link.storage_blob_dns_zone_link ]

  private_service_connection {
    name                           = "${local.prefix}-func-storage-psc"
    private_connection_resource_id = azurerm_storage_account.func_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.tags
}

// Function App

resource "azurerm_service_plan" "function_app_plan" {
  name                = "mcp-function-app-service-plan"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_function_app" "function_app" {
  name                = "mcp-function-app"
  resource_group_name = azurerm_resource_group.shared_rg.name
  location            = azurerm_resource_group.shared_rg.location
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_app_plan.id

  site_config {}
}

resource "azurerm_app_service_virtual_network_swift_connection" "function_app_vnet_integration" {
    app_service_id    = azurerm_linux_function_app.function_app.id
    subnet_id         = azurerm_subnet.function_apps.id
}
