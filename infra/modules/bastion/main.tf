# Azure Bastion Host Module

# Get the virtual network data
data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

# Create the AzureBastionSubnet for Basic and Standard SKUs
# Developer SKU does not require a dedicated subnet
resource "azurerm_subnet" "bastion" {
  count                = var.sku != "Developer" ? 1 : 0
  name                 = "AzureBastionSubnet" # This name is required by Azure
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]

  lifecycle {
    precondition {
      condition     = var.sku == "Developer" || (var.subnet_address_prefix != null && var.subnet_address_prefix != "")
      error_message = "subnet_address_prefix must be provided when using Basic or Standard SKU."
    }
  }

  # Bastion subnet cannot have any delegations or service endpoints
}

# Create Public IP for Basic and Standard SKUs
# Developer SKU does not require a public IP
resource "azurerm_public_ip" "bastion" {
  count               = var.sku != "Developer" ? 1 : 0
  name                = "${var.prefix}-bastion-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "${var.prefix}-bastion"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  scale_units         = var.sku == "Standard" ? var.scale_units : null
  
  # Developer SKU requires VNet ID instead of ip_configuration
  virtual_network_id = var.sku == "Developer" ? data.azurerm_virtual_network.vnet.id : null
  
  tags = var.tags

  # Copy/paste is available for Basic and Standard SKUs (not Developer)
  copy_paste_enabled = var.sku != "Developer" ? var.copy_paste_enabled : false

  # The following features are only available with Standard SKU
  tunneling_enabled        = var.sku == "Standard" ? var.enable_tunneling : false
  ip_connect_enabled       = var.sku == "Standard" ? var.enable_ip_connect : false
  shareable_link_enabled   = var.sku == "Standard" ? var.enable_shareable_link : false
  file_copy_enabled        = var.sku == "Standard" ? var.enable_file_copy : false

  # IP configuration is only required for Basic and Standard SKUs
  dynamic "ip_configuration" {
    for_each = var.sku != "Developer" ? [1] : []
    content {
      name                 = "bastion-ip-config"
      subnet_id            = azurerm_subnet.bastion[0].id
      public_ip_address_id = azurerm_public_ip.bastion[0].id
    }
  }
}
