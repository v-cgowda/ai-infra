locals {
    private_dns_zones = [
        {
            name         = "storage_blob"
            zone_name    = "privatelink.blob.core.windows.net"
            description  = "Private DNS zone for Storage Account Blob service"
        },
        {
            name         = "container_registry"
            zone_name    = "privatelink.azurecr.io"
            description  = "Private DNS zone for Container Registry"
        },
        {
            name         = "keyvault"
            zone_name    = "privatelink.vaultcore.azure.net"
            description  = "Private DNS zone for Key Vault"
        },
        {
            name         = "functions"
            zone_name    = "privatelink.azurewebsites.net"
            description  = "Private DNS zone for Function Apps"
        },
        {
            name         = "container_apps"
            zone_name    = "privatelink.${var.location}.azurecontainerapps.io"
            description  = "Private DNS zone for Container Apps"
        },
        {
            name         = "cosmosdb"
            zone_name    = "privatelink.documents.azure.com"
            description  = "Private DNS zone for Cosmos DB"
        },
        {
            name         = "cognitive_services"
            zone_name    = "privatelink.cognitiveservices.azure.com"
            description  = "Private DNS zone for Cognitive Services"
        },
        {
            name         = "openai"
            zone_name    = "privatelink.openai.azure.com"
            description  = "Private DNS zone for Azure Open AI"
        },
        {
            name         = "ai_services"
            zone_name    = "privatelink.services.ai.azure.com"
            description  = "Private DNS zone for Microsoft Foundry"
        }
    ]
}