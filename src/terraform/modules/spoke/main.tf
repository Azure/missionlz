# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

module "spoke-network" {
  source                              = "../virtual-network"
  location                            = var.location
  resource_group_name                 = var.spoke_rgname
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
  location             = var.location
  resource_group_name  = var.spoke_rgname
  virtual_network_name = var.spoke_vnetname
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  private_endpoint_network_policies_enabled     = lookup(each.value, "private_endpoint_network_policies_enabled", null)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", null)

  nsg_name  = each.value.nsg_name
  nsg_rules = each.value.nsg_rules

  routetable_name     = each.value.routetable_name
  firewall_ip_address = var.firewall_private_ip

  log_analytics_storage_id            = module.spoke-network.log_analytics_storage_id
  log_analytics_workspace_id          = var.laws_workspace_id
  log_analytics_workspace_location    = var.laws_location
  log_analytics_workspace_resource_id = var.laws_resource_id

  tags = var.tags
}
