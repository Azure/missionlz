# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

module "hub-network" {
  source                              = "../virtual-network"
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  vnet_name                           = var.vnet_name
  vnet_address_space                  = var.vnet_address_space
  log_analytics_workspace_resource_id = var.log_analytics_workspace_resource_id
  tags                                = var.tags
}

resource "azurerm_subnet" "fw_client" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = module.hub-network.resource_group_name
  virtual_network_name = module.hub-network.virtual_network_name
  address_prefixes     = [cidrsubnet(var.client_address_space, 0, 0)]
}

resource "azurerm_subnet" "fw_mgmt" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = module.hub-network.resource_group_name
  virtual_network_name = module.hub-network.virtual_network_name
  address_prefixes     = [cidrsubnet(var.management_address_space, 0, 0)]
}

resource "azurerm_route_table" "routetable" {
  name                          = "FirewallRouteTable"
  resource_group_name           = azurerm_subnet.fw_mgmt.resource_group_name
  location                      = var.location
  disable_bgp_route_propagation = true
  tags                          = var.tags
}

resource "azurerm_route" "default_route" {
  name                = "FirewallDefaultRoute"
  resource_group_name = azurerm_route_table.routetable.resource_group_name
  route_table_name    = "FirewallRouteTable"
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [
    azurerm_route.default_route
  ]

  create_duration = "30s"
}

resource "azurerm_subnet_route_table_association" "routetable" {
  depends_on = [
    azurerm_route.default_route,
    time_sleep.wait_30_seconds
  ]

  subnet_id      = azurerm_subnet.fw_mgmt.id
  route_table_id = azurerm_route_table.routetable.id
}
