# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = module.hub-network.resource_group_name
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = module.hub-network.resource_group_location
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = module.hub-network.virtual_network_name
}

output "virtual_network_address_space" {
  description = "List of address spaces that are used the virtual network."
  value       = module.hub-network.virtual_network_address_space
}

output "firewall_subnet_name" {
  value = azurerm_subnet.firewall.name
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.loganalytics.name
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.loganalytics.id
}
