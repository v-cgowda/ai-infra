output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.workload_vnet.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.workload_vnet.name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to address prefixes"
  value       = { for k, v in azurerm_subnet.subnet : k => v.address_prefixes[0] }
}

output "network_security_group_ids" {
  description = "Map of NSG names to IDs"
  value       = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to IDs"
  value       = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone names to DNS names"
  value       = { for k, v in azurerm_private_dns_zone.zones : k => v.name }
}