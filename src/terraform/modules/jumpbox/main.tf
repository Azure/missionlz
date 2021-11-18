# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "random_id" "jumpbox-keyvault" {
  byte_length = 12
}

resource "azurerm_key_vault" "jumpbox-keyvault" {
  name                       = format("%.24s", lower(replace("${var.keyvault_name}${random_id.jumpbox-keyvault.id}", "/[[:^alnum:]]/", "")))
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = 90
  sku_name                   = "standard" # 'standard' or 'premium' case sensitive

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    key_permissions = [
      "create",
      "get",
    ]

    secret_permissions = [
      "set",
      "get",
      "delete",
      "purge",
      "recover"
    ]
  }

  tags = var.tags
}

resource "azurerm_key_vault_secret" "jumpbox-username" {
  name         = "jumpbox-username"
  value        = var.admin_username
  key_vault_id = azurerm_key_vault.jumpbox-keyvault.id
}

resource "random_integer" "windows-jumpbox-password" {
  min = 8
  max = 123
}

resource "random_password" "windows-jumpbox-password" {
  length      = random_integer.windows-jumpbox-password.result
  upper       = true
  lower       = true
  number      = true
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "windows-jumpbox-password" {
  name         = "windows-jumpbox-password"
  value        = random_password.windows-jumpbox-password.result
  key_vault_id = azurerm_key_vault.jumpbox-keyvault.id
}

resource "random_integer" "linux-jumpbox-password" {
  min = 6
  max = 72
}

resource "random_password" "linux-jumpbox-password" {
  length      = random_integer.linux-jumpbox-password.result
  upper       = true
  lower       = true
  number      = true
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_key_vault_secret" "linux-jumpbox-password" {
  name         = "linux-jumpbox-password"
  value        = random_password.linux-jumpbox-password.result
  key_vault_id = azurerm_key_vault.jumpbox-keyvault.id
}

module "windows-virtual-machine" {
  source               = "../windows-virtual-machine"
  resource_group_name  = var.resource_group_name
  location             = var.location
  virtual_network_name = var.virtual_network_name
  subnet_name          = var.subnet_name
  name                 = var.windows_name
  size                 = var.windows_size
  admin_username       = var.admin_username
  admin_password       = random_password.windows-jumpbox-password.result
  publisher            = var.windows_publisher
  offer                = var.windows_offer
  sku                  = var.windows_sku
  image_version        = var.windows_image_version
  tags                 = var.tags
}

module "linux-virtual-machine" {
  source               = "../linux-virtual-machine"
  resource_group_name  = var.resource_group_name
  location             = var.location
  virtual_network_name = var.virtual_network_name
  subnet_name          = var.subnet_name
  name                 = var.linux_name
  size                 = var.linux_size
  admin_username       = var.admin_username
  admin_password       = random_password.linux-jumpbox-password.result
  publisher            = var.linux_publisher
  offer                = var.linux_offer
  sku                  = var.linux_sku
  image_version        = var.linux_image_version
  tags                 = var.tags
}
