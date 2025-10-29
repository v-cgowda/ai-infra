

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
  name                 = "${local.prefix}-dmz"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 0)]
}
resource "azurerm_subnet_network_security_group_association" "nsg_dmz" {
  subnet_id                 = azurerm_subnet.dmz.id
  network_security_group_id = azurerm_network_security_group.dmz_nsg.id
}

// subnet for container apps with address of 10.0.1.0/24
resource "azurerm_subnet" "container_apps" {
  name                 = "${local.prefix}-containerapps"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 1)]
}
resource "azurerm_subnet_network_security_group_association" "nsg_container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.compute_nsg.id
}

// subnet for PaaS services with address of 10.0.2.0/24
resource "azurerm_subnet" "services" {
  name                 = "${local.prefix}-services"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 2)]

}
resource "azurerm_subnet_network_security_group_association" "nsg_services" {
  subnet_id                 = azurerm_subnet.services.id
  network_security_group_id = azurerm_network_security_group.compute_nsg.id
}

// subnet for function apps with address of 10.0.3.0/24
resource "azurerm_subnet" "function_apps" {
  name                 = "${local.prefix}-functionapps"
  resource_group_name  = azurerm_resource_group.shared_rg.name
  virtual_network_name = azurerm_virtual_network.workload_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 8, 3)]

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

