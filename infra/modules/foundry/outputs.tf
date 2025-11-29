# Foundry Module Outputs

output "foundry_service" {
  description = "Azure AI Foundry service information"
  value = {
    id       = azapi_resource.foundry.id
    name     = azapi_resource.foundry.name
    # Note: To get endpoint and keys, use azapi_resource_action with listKeys
  }
}

output "foundry_deployments" {
  description = "Foundry model deployments"
  value = {
    for name, deployment in azapi_resource.foundry_deployments : name => {
      id   = deployment.id
      name = deployment.name
    }
  }
}

output "foundry_managed_identity" {
  description = "Managed identity of the Foundry service"
  value = azapi_resource.foundry.identity.principal_id
}
