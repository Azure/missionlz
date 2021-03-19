# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  version         = "~> 2.50.0"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  tenant_id       = var.mlz_tenantid
  subscription_id = var.saca_subid
  client_id       = var.mlz_clientid
  client_secret   = var.mlz_clientsecret

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}

provider "random" {
  version = "3.1.0"
}

resource "azurerm_resource_group" "hub" {
  location = var.mlz_location
  name     = var.saca_rgname
}

module "saca-hub-network" {
  depends_on             = [azurerm_resource_group.hub]
  source                 = "../../modules/hub"
  location               = var.mlz_location
  resource_group_name    = azurerm_resource_group.hub.name
  vnet_name              = var.saca_vnetname
  vnet_address_space     = var.vnet_address_space
  firewall_address_space = var.firewall_address_space

  log_analytics_workspace_name              = var.saca_lawsname
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_retention_in_days = "30"

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "saca-firewall" {
  depends_on             = [module.saca-hub-network]
  source                 = "../../modules/firewall"
  location               = var.mlz_location
  resource_group_name    = module.saca-hub-network.resource_group_name
  vnet_name              = module.saca-hub-network.virtual_network_name
  vnet_address_space     = module.saca-hub-network.virtual_network_address_space
  firewall_subnet_name   = module.saca-hub-network.firewall_subnet_name
  firewall_address_space = var.firewall_address_space
  saca_fwname            = var.saca_fwname
  firewall_ipconfig_name = var.firewall_ipconfig_name
  public_ip_name         = var.public_ip_name

  log_analytics_workspace_id = module.saca-hub-network.log_analytics_workspace_id

  tags = {
    DeploymentName = var.deploymentname
  }
}
