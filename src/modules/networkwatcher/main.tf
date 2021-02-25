# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
resource "azurerm_resource_group" "networkwatcher" {
  name     = "${var.name_prefix}-networkwatcher-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_network_watcher" "networkwatcher" {
  name                = "${var.name_prefix}-networkwatcher"
  location            = azurerm_resource_group.networkwatcher.location
  resource_group_name = azurerm_resource_group.networkwatcher.name
  tags                = var.tags
}
