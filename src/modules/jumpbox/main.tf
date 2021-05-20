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
}

resource "random_password" "jumpbox-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "jumpbox-password" {
  name         = "jumpbox-password"
  value        = random_password.jumpbox-password.result
  key_vault_id = azurerm_key_vault.jumpbox-keyvault.id
}

resource "random_string" "jumpbox-username" {
  length  = 12
  special = false
}

resource "azurerm_key_vault_secret" "jumpbox-username" {
  name         = "jumpbox-username"
  value        = random_string.jumpbox-username.result
  key_vault_id = azurerm_key_vault.jumpbox-keyvault.id
}

module "jumpbox-virtual-machine" {
  source               = "../windows-virtual-machine"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  subnet_name          = var.subnet_name
  name                 = var.name
  size                 = var.size
  admin_username       = azurerm_key_vault_secret.jumpbox-username.value
  admin_password       = azurerm_key_vault_secret.jumpbox-password.value
  publisher            = var.publisher
  offer                = var.offer
  sku                  = var.sku
  image_version        = var.image_version
}
