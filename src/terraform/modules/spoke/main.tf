# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "azurerm_resource_group" "spoke" {
  name = var.spoke_rgname
}

data "azurerm_resource_group" "hub" {
  name = var.hub_rgname
}

data "azurerm_virtual_network" "hub" {
  name                = var.hub_vnetname
  resource_group_name = data.azurerm_resource_group.hub.name
}

data "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  resource_group_name = var.firewall_rg_name
}

module "spoke-network" {
  depends_on                          = [data.azurerm_resource_group.spoke]
  source                              = "../virtual-network"
  location                            = data.azurerm_resource_group.spoke.location
  resource_group_name                 = data.azurerm_resource_group.spoke.name
  vnet_name                           = var.spoke_vnetname
  vnet_address_space                  = var.spoke_vnet_address_space
  log_analytics_workspace_resource_id = var.laws_resource_id

  tags = var.tags
}

module "subnets" {
  depends_on = [module.spoke-network]
  source     = "../subnet"
  for_each   = var.subnets

  name                 = each.value.name
  location             = data.azurerm_resource_group.spoke.location
  resource_group_name  = module.spoke-network.resource_group_name
  virtual_network_name = module.spoke-network.virtual_network_name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)

  nsg_name  = each.value.nsg_name
  nsg_rules = each.value.nsg_rules

  routetable_name     = each.value.routetable_name
  firewall_ip_address = data.azurerm_firewall.firewall.ip_configuration[0].private_ip_address

  log_analytics_storage_id            = module.spoke-network.log_analytics_storage_id
  log_analytics_workspace_id          = var.laws_workspace_id
  log_analytics_workspace_location    = var.laws_location
  log_analytics_workspace_resource_id = var.laws_resource_id

  tags = var.tags
}

module "outbound-peering" {
  source = "../virtual-network-peering"

  source_rg_name              = module.spoke-network.resource_group_name
  source_vnet_name            = module.spoke-network.virtual_network_name
  destination_vnet_name       = data.azurerm_virtual_network.hub.name
  destination_rg_name         = data.azurerm_resource_group.hub.name
  destination_subscription_id = var.hub_subid

  tags = var.tags
}

module "inbound-peering" {
  source = "../virtual-network-peering"

  source_vnet_name            = data.azurerm_virtual_network.hub.name
  source_rg_name              = data.azurerm_resource_group.hub.name
  destination_vnet_name       = module.spoke-network.virtual_network_name
  destination_rg_name         = module.spoke-network.resource_group_name
  destination_subscription_id = var.spoke_subid

  tags = var.tags
}
