# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "firewall_public_ip" {
  description = "The public IP for the firewall"
  value       = azurerm_public_ip.fw_client_pip.ip_address
}

output "firewall_private_ip" {
  description = "The private IP for the firewall"
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

output "firewall_name" {
  description = "The name of the firewall"
  value       = azurerm_firewall.firewall.name
}
