# Azure Form Recognizer (Document Intelligence)
resource "azurerm_cognitive_account" "form_recognizer" {
  count               = var.form_recognizer_enabled ? 1 : 0
  name                = "${var.project_name}-docint-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "FormRecognizer"
  sku_name            = "S0"

  custom_subdomain_name = "${var.project_name}-docint-${var.environment}"

  # Network restrictions
  network_acls {
    default_action = var.network_restrictions.default_action
    
    dynamic "ip_rules" {
      for_each = var.network_restrictions.ip_rules
      content {
        ip_range = ip_rules.value
      }
    }

    dynamic "virtual_network_rules" {
      for_each = var.network_restrictions.virtual_network_rules
      content {
        subnet_id = virtual_network_rules.value.subnet_id
      }
    }
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Module  = "ai-services"
    Service = "FormRecognizer"
  })
}

# Private Endpoints for Form Recognizer
resource "azurerm_private_endpoint" "form_recognizer" {
  count               = var.private_endpoint_info.subnet_id != "" && var.form_recognizer_enabled ? 1 : 0
  name                = "${azurerm_cognitive_account.form_recognizer[0].name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_info.subnet_id

  private_service_connection {
    name                           = "${azurerm_cognitive_account.form_recognizer[0].name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.form_recognizer[0].id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint_info.dns_zone_id != "" ? [1] : []
    content {
      name                 = "form-recognizer-dns-zone-group"
      private_dns_zone_ids = [var.private_endpoint_info.dns_zone_id]
    }
  }

  tags = merge(var.tags, {
    Module = "ai-services"
  })
}# Azure Computer Vision
resource "azurerm_cognitive_account" "computer_vision" {
  count               = var.computer_vision_enabled ? 1 : 0
  name                = "${var.project_name}-vision-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "ComputerVision"
  sku_name            = "S1"

  # Network restrictions
  network_acls {
    default_action = var.network_restrictions.default_action
    
    dynamic "ip_rules" {
      for_each = var.network_restrictions.ip_rules
      content {
        ip_range = ip_rules.value
      }
    }

    dynamic "virtual_network_rules" {
      for_each = var.network_restrictions.virtual_network_rules
      content {
        subnet_id = virtual_network_rules.value.subnet_id
      }
    }
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Module  = "ai-services"
    Service = "ComputerVision"
  })
}

# Private Endpoints for Computer Vision
resource "azurerm_private_endpoint" "computer_vision" {
  count               = var.private_endpoint_info.subnet_id != "" && var.computer_vision_enabled ? 1 : 0
  name                = "${azurerm_cognitive_account.computer_vision[0].name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_info.subnet_id

  private_service_connection {
    name                           = "${azurerm_cognitive_account.computer_vision[0].name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.computer_vision[0].id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint_info.dns_zone_id != "" ? [1] : []
    content {
      name                 = "computer-vision-dns-zone-group"
      private_dns_zone_ids = [var.private_endpoint_info.dns_zone_id]
    }
  }

  tags = merge(var.tags, {
    Module = "ai-services"
  })
}

# Store API keys in Key Vault
resource "azurerm_key_vault_secret" "form_recognizer_key" {
  count        = var.key_vault_id != "" && length(azurerm_cognitive_account.form_recognizer) > 0 ? 1 : 0
  name         = "form-recognizer-api-key"
  value        = azurerm_cognitive_account.form_recognizer[0].primary_access_key
  key_vault_id = var.key_vault_id

  tags = merge(var.tags, {
    Module = "ai-services"
  })
}
