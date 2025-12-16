output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.vm_nic.id
}

output "setup_script_extension_id" {
  description = "ID of the Custom Script Extension (if created)"
  value       = length(azurerm_virtual_machine_extension.setup_script) > 0 ? azurerm_virtual_machine_extension.setup_script[0].id : null
}
