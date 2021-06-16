# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "saca_rg_name" {
  value = azurerm_resource_group.hub.name
}

output "saca_firewall_name" {
  value = module.saca-firewall.firewall_name
}

output "laws_name" {
  value = module.saca-hub-network.log_analytics_workspace_name
}

output "vnet_name" {
  value = module.saca-hub-network.virtual_network_name
}
