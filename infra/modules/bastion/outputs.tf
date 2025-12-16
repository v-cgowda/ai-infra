output "bastion_id" {
  description = "ID of the Azure Bastion Host"
  value       = azurerm_bastion_host.bastion.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion Host"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_dns_name" {
  description = "DNS name of the Azure Bastion Host"
  value       = azurerm_bastion_host.bastion.dns_name
}

output "bastion_subnet_id" {
  description = "ID of the AzureBastionSubnet (null for Developer SKU)"
  value       = length(azurerm_subnet.bastion) > 0 ? azurerm_subnet.bastion[0].id : null
}

output "public_ip_address" {
  description = "Public IP address of the Bastion Host (null for Developer SKU)"
  value       = length(azurerm_public_ip.bastion) > 0 ? azurerm_public_ip.bastion[0].ip_address : null
}

output "public_ip_id" {
  description = "ID of the Public IP for Bastion Host (null for Developer SKU)"
  value       = length(azurerm_public_ip.bastion) > 0 ? azurerm_public_ip.bastion[0].id : null
}
