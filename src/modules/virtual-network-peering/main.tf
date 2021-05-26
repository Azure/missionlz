# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.55.0"
    }
  }
}

resource "azurerm_virtual_network_peering" "src-to-dest" {
  name                         = "${var.source_vnet_name}-to-${var.destination_vnet_name}"
  resource_group_name          = var.source_rg_name
  virtual_network_name         = var.source_vnet_name
  remote_virtual_network_id    = "/subscriptions/${var.destination_subscription_id}/resourceGroups/${var.destination_rg_name}/providers/Microsoft.Network/virtualNetworks/${var.destination_vnet_name}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
