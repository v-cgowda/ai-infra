# Virtual Network
resource "azurerm_virtual_network" "workload_vnet" {
  name                = var.prefix
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.cidr]
  tags                = var.tags
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg" {
  for_each = var.network_security_groups
  
  name                = "${var.prefix}-${each.value.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnet" {
  for_each = var.subnets
  
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [each.value.address_prefix]
  
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = { for k, v in var.subnets : k => v if v.nsg_name != null }
  
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_name].id
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "zones" {
  for_each = var.enable_private_dns_zones ? { for zone in var.private_dns_zones : zone.name => zone } : {}
  
  name                = each.value.zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "zone_links" {
  for_each = var.enable_private_dns_zones ? { for zone in var.private_dns_zones : zone.name => zone } : {}
  
  name                  = "${each.value.name}-dns-zone-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.workload_vnet.id
  tags                  = var.tags
}