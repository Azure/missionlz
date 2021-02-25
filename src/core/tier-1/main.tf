# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.45.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  tenant_id       = var.mlz_tenantid
  subscription_id = var.tier1_subid
  client_id       = var.mlz_clientid
  client_secret   = var.mlz_clientsecret

  features {}
}

provider "azurerm" {
  alias           = "hub"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  tenant_id       = var.mlz_tenantid
  subscription_id = var.saca_subid
  client_id       = var.mlz_clientid
  client_secret   = var.mlz_clientsecret

  features {}
}

data "azurerm_resource_group" "hub" {
  provider = azurerm.hub
  name     = var.saca_rgname
}

data "azurerm_virtual_network" "hub" {
  provider            = azurerm.hub
  name                = var.saca_vnetname
  resource_group_name = data.azurerm_resource_group.hub.name
}

data "azurerm_log_analytics_workspace" "hub" {
  provider            = azurerm.hub
  name                = var.saca_lawsname
  resource_group_name = data.azurerm_resource_group.hub.name
}

data "azurerm_firewall" "firewall" {
  provider            = azurerm.hub
  name                = var.saca_fwname
  resource_group_name = data.azurerm_resource_group.hub.name
}

resource "azurerm_resource_group" "t1" {
  location = var.mlz_location
  name     = var.tier1_rgname
}

module "t1-network" {
  depends_on                 = [azurerm_resource_group.t1, data.azurerm_log_analytics_workspace.hub]
  source                     = "../../modules/virtual-network"
  location                   = azurerm_resource_group.t1.location
  resource_group_name        = azurerm_resource_group.t1.name
  vnet_name                  = var.tier1_vnetname
  vnet_address_space         = var.vnet_address_space
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.hub.id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "t1-subnets" {
  depends_on = [module.t1-network, data.azurerm_log_analytics_workspace.hub]
  source     = "../../modules/subnet"
  for_each   = var.subnets

  name                 = each.value.name
  location             = var.mlz_location
  resource_group_name  = module.t1-network.resource_group_name
  virtual_network_name = module.t1-network.virtual_network_name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  enforce_private_link_endpoint_network_policies = lookup(each.value, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(each.value, "enforce_private_link_service_network_policies", null)

  nsg_name  = each.value.nsg_name
  nsg_rules = each.value.nsg_rules

  routetable_name     = each.value.routetable_name
  firewall_ip_address = data.azurerm_firewall.firewall.ip_configuration[0].private_ip_address

  log_analytics_storage_id   = module.t1-network.log_analytics_storage_id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.hub.id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "t1-outbound-peering" {
  source = "../../modules/virtual-network-outbound-peering"

  source_rg_name              = module.t1-network.resource_group_name
  source_vnet_name            = module.t1-network.virtual_network_name
  destination_vnet_name       = data.azurerm_virtual_network.hub.name
  destination_rg_name         = data.azurerm_resource_group.hub.name
  destination_subscription_id = var.saca_subid

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "t1-networkwatcher" {
  count  = var.create_network_watcher == true ? 1 : 0
  source = "../../modules/networkwatcher"

  name_prefix = module.t1-network.resource_group_name
  location    = module.t1-network.resource_group_location

  tags = {
    DeploymentName = var.deploymentname
  }
}
