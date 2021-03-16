# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "nw_name" {
  value = azurerm_network_watcher.networkwatcher.name
}

output "nw_rg_name" {
  value = azurerm_network_watcher.networkwatcher.resource_group_name
}
