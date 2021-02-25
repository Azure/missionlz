# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

module "hub-network" {
  source                     = "../virtual-network"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  vnet_name                  = var.vnet_name
  vnet_address_space         = var.vnet_address_space
  log_analytics_workspace_id = azurerm_log_analytics_workspace.loganalytics.id
  tags                       = var.tags
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = module.hub-network.resource_group_name
  virtual_network_name = module.hub-network.virtual_network_name
  address_prefixes     = [cidrsubnet(var.firewall_address_space, 0, 0)]
}

resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = var.log_analytics_workspace_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_analytics_workspace_retention_in_days
  tags                = var.tags
}
