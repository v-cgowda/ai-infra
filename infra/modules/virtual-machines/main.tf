# Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.prefix}-${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.prefix}-${var.vm_name}"
  computer_name       = var.computer_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  custom_data = var.custom_data != "" ? base64encode(var.custom_data) : null
}

# Custom Script Extension - executes PowerShell script on VM startup
resource "azurerm_virtual_machine_extension" "setup_script" {
  count                = var.setup_script != "" ? 1 : 0
  name                 = "setup-script"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  auto_upgrade_minor_version = true
  tags                 = var.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File ${var.setup_script_name}"
    script          = base64encode(var.setup_script)
  })

  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
}
