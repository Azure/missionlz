# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "laws_name" {
  description = "LAWS Name"
  value       = azurerm_log_analytics_workspace.laws.name
}

output "laws_rgname" {
  description = "Resource Group for Laws"
  value       = azurerm_log_analytics_workspace.laws.resource_group_name
}

output "firewall_private_ip" {
  description = "Firewall private IP"
  value       = module.firewall.firewall_private_ip
}
