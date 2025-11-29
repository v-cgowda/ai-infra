# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.project_name}-${var.environment}-cae"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Container App Environment identity
    identity {
    type = "SystemAssigned"
  }

  # Network configuration
  infrastructure_subnet_id          = var.subnet_id
  internal_load_balancer_enabled    = false
  public_network_access             = var.public_network_access

  # Dapr configuration
  dapr_application_insights_connection_string = null

  # Workload profile configuration
  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      maximum_count         = workload_profile.value.maximum_count
      minimum_count         = workload_profile.value.minimum_count
    }
  }
  
  tags = merge(var.tags, {
    Module = "container-apps"
  })
}

# Private Endpoint for Container Apps Environment
resource "azurerm_private_endpoint" "container_apps_environment" {
  count               = var.private_endpoint_subnet_id != "" ? 1 : 0
  name                = "${var.project_name}-${var.environment}-cae-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  
  private_service_connection {
    name                           = "${var.project_name}-${var.environment}-cae-psc"
    private_connection_resource_id = azurerm_container_app_environment.main.id
    subresource_names              = ["managedEnvironments"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "container-apps-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = merge(var.tags, {
    Module = "container-apps"
  })
}

# Container Registry Secret
/*
resource "azurerm_container_app_environment_storage" "registry" {
  count                        = var.container_registry_id != "" ? 1 : 0
  name                         = "registry-storage"
  container_app_environment_id = azurerm_container_app_environment.main.id
  account_name                 = split("/", var.container_registry_id)[8] # Extract ACR name
  share_name                   = "registry"
  access_key                   = "" # Will be managed through managed identity
  access_mode                  = "ReadOnly"
}
*/

# Container Apps
resource "azurerm_container_app" "apps" {
  for_each = {
    for app in var.container_apps : app.name => app
  }

  name                         = "${var.project_name}-${each.value.name}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  workload_profile_name = each.value.workload_profile_name != "" ? each.value.workload_profile_name : null

  # Identity configuration
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }

  # Registry configuration
  dynamic "registry" {
    for_each = var.container_registry_server != "" ? [1] : []
    content {
      server   = var.container_registry_server
      identity = var.managed_identity_id
    }
  }

  # Template configuration
  template {
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas

    container {
      name   = each.value.name
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory

      # Environment variables
      dynamic "env" {
        for_each = each.value.env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      # Secrets as environment variables
      dynamic "env" {
        for_each = each.value.secrets
        content {
          name        = env.value.name
          secret_name = env.value.name
        }
      }
    }
  }

  # Secrets
  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  # Ingress configuration
  dynamic "ingress" {
    for_each = each.value.external_ingress ? [1] : []
    content {
      allow_insecure_connections = false
      external_enabled           = true
      target_port                = each.value.target_port

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  tags = merge(var.tags, {
    Module = "container-apps"
    App    = each.value.name
  })
}
