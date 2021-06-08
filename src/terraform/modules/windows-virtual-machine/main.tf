# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "azurerm_resource_group" "vm_resource_group" {
  name = var.resource_group_name
}

data "azurerm_subnet" "vm_subnet" {
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_network_interface" "windows_vm" {
  name                = "${var.name}_NIC"
  resource_group_name = data.azurerm_resource_group.vm_resource_group.name
  location            = data.azurerm_resource_group.vm_resource_group.location

  ip_configuration {
    name                          = "${var.name}_IPCONFIG"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windows_vm" {
  name                = var.name
  computer_name       = substr(var.name, 0, 14) # computer_name can only be 15 characters maximum
  resource_group_name = data.azurerm_resource_group.vm_resource_group.name
  location            = data.azurerm_resource_group.vm_resource_group.location
  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.windows_vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }
}
