# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
terraform {
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.55.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.1.0"
    }
  }
}

provider "azurerm" {
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
}

provider "time" {
  version = "0.7.1"
}

resource "azurerm_resource_group" "hub" {
  location = var.mlz_location
  name     = var.saca_rgname

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "saca-hub-network" {
  depends_on               = [azurerm_resource_group.hub]
  source                   = "../../modules/hub"
  location                 = var.mlz_location
  resource_group_name      = azurerm_resource_group.hub.name
  vnet_name                = var.saca_vnetname
  vnet_address_space       = var.vnet_address_space
  firewall_address_space   = var.firewall_address_space
  management_address_space = var.management_address_space
  routetable_name          = var.mgmt_routetable_name

  log_analytics_workspace_name              = var.saca_lawsname
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_retention_in_days = "30"

  tags = {
    DeploymentName = var.deploymentname
  }
}

locals {
  # azurerm terraform environments where Azure Firewall Premium is supported
  firewall_premium_tf_environments = ["public"]
}

module "saca-firewall" {
  depends_on             = [module.saca-hub-network]
  source                 = "../../modules/firewall"
  location               = var.mlz_location
  resource_group_name    = module.saca-hub-network.resource_group_name
  vnet_name              = module.saca-hub-network.virtual_network_name
  vnet_address_space     = module.saca-hub-network.virtual_network_address_space
  firewall_sku           = contains(local.firewall_premium_tf_environments, lower(var.tf_environment)) ? "Premium" : "Standard"
  fw_client_sn_name      = module.saca-hub-network.fw_client_subnet_name
  fw_mgmt_sn_name        = module.saca-hub-network.fw_mgmt_subnet_name
  firewall_address_space = var.firewall_address_space
  saca_fwname            = var.saca_fwname
  fw_client_ipcfg_name   = var.fw_client_ipcfg_name
  fw_client_pip_name     = var.fw_client_pip_name
  fw_mgmt_ipcfg_name     = var.fw_mgmt_ipcfg_name
  fw_mgmt_pip_name       = var.fw_mgmt_pip_name

  log_analytics_workspace_id = module.saca-hub-network.log_analytics_workspace_id

  tags = {
    DeploymentName = var.deploymentname
  }
}
