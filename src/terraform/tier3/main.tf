# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
terraform {
  backend "local" {}

  required_version = "= 1.0.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.69.0"
    }
  }
}

provider "azurerm" {
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  subscription_id = var.hub_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "hub"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  subscription_id = var.hub_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "tier1"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  subscription_id = var.tier1_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "tier3"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  subscription_id = var.tier3_subid

  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

################################
### STAGE 0: Scaffolding     ###
################################

resource "azurerm_resource_group" "tier3" {
  provider = azurerm.tier3

  location = var.mlz_location
  name     = var.tier3_rgname

  tags = {
    DeploymentName = var.deploymentname
  }
}

################################
### STAGE 1: Logging         ###
################################

data "azurerm_log_analytics_workspace" "laws" {
  provider = azurerm.tier1

  name                = var.laws_name.value
  resource_group_name = var.laws_rgname.value
}

################################
### STAGE 2: Networking      ###
################################

data "azurerm_virtual_network" "hub" {
  name                = var.hub_vnetname
  resource_group_name = var.hub_rgname
}


module "spoke-network-t3" {
  providers  = { azurerm = azurerm.tier3 }
  depends_on = [azurerm_resource_group.tier3]
  source     = "../modules/spoke"

  location = azurerm_resource_group.tier3.location

  firewall_private_ip = var.firewall_private_ip.value

  laws_location     = var.mlz_location
  laws_workspace_id = data.azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id  = data.azurerm_log_analytics_workspace.laws.id

  spoke_rgname             = var.tier3_rgname
  spoke_vnetname           = var.tier3_vnetname
  spoke_vnet_address_space = var.tier3_vnet_address_space
  subnets                  = var.tier3_subnets

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_virtual_network_peering" "t3-to-hub" {
  provider   = azurerm.tier3
  depends_on = [azurerm_resource_group.tier3, module.spoke-network-t3]

  name                         = "${var.tier3_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = var.tier3_rgname
  virtual_network_name         = var.tier3_vnetname
  remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub-to-t3" {
  provider   = azurerm.hub
  depends_on = [module.spoke-network-t3]

  name                         = "${var.hub_vnetname}-to-${var.tier3_vnetname}"
  resource_group_name          = var.hub_rgname
  virtual_network_name         = var.hub_vnetname
  remote_virtual_network_id    = module.spoke-network-t3.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
