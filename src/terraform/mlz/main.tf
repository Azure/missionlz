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
    time = {
      source  = "hashicorp/time"
      version = "0.7.1"
    }
  }
}

provider "azurerm" {
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  tenant_id       = var.mlz_tenantid
  subscription_id = var.hub_subid
  client_id       = var.mlz_clientid
  client_secret   = var.mlz_clientsecret

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
  tenant_id       = var.mlz_tenantid
  subscription_id = var.hub_subid
  client_id       = var.mlz_clientid
  client_secret   = var.mlz_clientsecret

  features {}
}

provider "random" {
}

provider "time" {
}

module "saca-hub" {
  source                       = "../core/saca-hub"
  tf_environment               = var.tf_environment
  mlz_cloud                    = var.mlz_cloud
  mlz_tenantid                 = var.mlz_tenantid
  mlz_location                 = var.mlz_location
  mlz_metadatahost             = var.mlz_metadatahost
  mlz_clientid                 = var.mlz_clientid
  mlz_clientsecret             = var.mlz_clientsecret
  mlz_objectid                 = var.mlz_objectid
  deploymentname               = var.deploymentname
  saca_subid                   = var.hub_subid
  saca_rgname                  = var.hub_rgname
  saca_vnetname                = var.hub_vnetname
  saca_lawsname                = var.hub_lawsname
  vnet_address_space           = var.vnet_address_space
  client_address_space         = var.client_address_space
  management_address_space     = var.management_address_space
  firewall_name                = var.firewall_name
  firewall_policy_name         = var.firewall_policy_name
  client_ipconfig_name         = var.client_ipconfig_name
  client_publicip_name         = var.client_publicip_name
  management_ipconfig_name     = var.management_ipconfig_name
  management_publicip_name     = var.management_publicip_name
  management_routetable_name   = var.management_routetable_name
  create_network_watcher       = var.create_network_watcher
  create_bastion_jumpbox       = var.create_bastion_jumpbox
  bastion_host_name            = var.bastion_host_name
  bastion_address_space        = var.bastion_address_space
  bastion_public_ip_name       = var.bastion_public_ip_name
  bastion_ipconfig_name        = var.bastion_ipconfig_name
  jumpbox_subnet               = var.jumpbox_subnet
  jumpbox_keyvault_name        = var.jumpbox_keyvault_name
  jumpbox_windows_vm_name      = var.jumpbox_windows_vm_name
  jumpbox_windows_vm_size      = var.jumpbox_windows_vm_size
  jumpbox_windows_vm_publisher = var.jumpbox_windows_vm_publisher
  jumpbox_windows_vm_offer     = var.jumpbox_windows_vm_offer
  jumpbox_windows_vm_sku       = var.jumpbox_windows_vm_sku
  jumpbox_windows_vm_version   = var.jumpbox_windows_vm_version
  jumpbox_linux_vm_name        = var.jumpbox_linux_vm_name
  jumpbox_linux_vm_size        = var.jumpbox_linux_vm_size
  jumpbox_linux_vm_publisher   = var.jumpbox_linux_vm_publisher
  jumpbox_linux_vm_offer       = var.jumpbox_linux_vm_offer
  jumpbox_linux_vm_sku         = var.jumpbox_linux_vm_sku
  jumpbox_linux_vm_version     = var.jumpbox_linux_vm_version

}

module "tier0" {
  source                   = "../core/tier-0"
  tf_environment           = var.tf_environment
  mlz_cloud                = var.mlz_cloud
  mlz_tenantid             = var.mlz_tenantid
  mlz_location             = var.mlz_location
  mlz_metadatahost         = var.mlz_metadatahost
  mlz_clientid             = var.mlz_clientid
  mlz_clientsecret         = var.mlz_clientsecret
  mlz_objectid             = var.mlz_objectid
  deploymentname           = var.deploymentname
  saca_subid               = var.hub_subid
  saca_rgname              = module.saca-hub.saca_rg_name
  saca_vnetname            = module.saca-hub.vnet_name
  firewall_name            = module.saca-hub.saca_firewall_name
  saca_lawsname            = module.saca-hub.laws_name
  tier0_subid              = var.tier0_subid
  tier0_rgname             = var.tier0_rgname
  tier0_vnetname           = var.tier0_vnetname
  tier0_vnet_address_space = var.tier0_vnet_address_space
  subnets                  = var.tier0_subnets
  create_network_watcher   = var.tier0_create_network_watcher
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }
  depends_on = [
    module.saca-hub,
  ]
}

module "tier1" {
  source                   = "../core/tier-1"
  tf_environment           = var.tf_environment
  mlz_cloud                = var.mlz_cloud
  mlz_tenantid             = var.mlz_tenantid
  mlz_location             = var.mlz_location
  mlz_metadatahost         = var.mlz_metadatahost
  mlz_clientid             = var.mlz_clientid
  mlz_clientsecret         = var.mlz_clientsecret
  mlz_objectid             = var.mlz_objectid
  deploymentname           = var.deploymentname
  saca_subid               = var.hub_subid
  saca_rgname              = module.saca-hub.saca_rg_name
  saca_vnetname            = module.saca-hub.vnet_name
  firewall_name            = module.saca-hub.saca_firewall_name
  saca_lawsname            = module.saca-hub.laws_name
  tier1_subid              = var.tier1_subid
  tier1_rgname             = var.tier1_rgname
  tier1_vnetname           = var.tier1_vnetname
  tier1_vnet_address_space = var.tier1_vnet_address_space
  subnets                  = var.tier1_subnets
  create_network_watcher   = var.tier1_create_network_watcher
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }
  depends_on = [
    module.saca-hub,
  ]
}

module "tier2" {
  source                   = "../core/tier-2"
  tf_environment           = var.tf_environment
  mlz_cloud                = var.mlz_cloud
  mlz_tenantid             = var.mlz_tenantid
  mlz_location             = var.mlz_location
  mlz_metadatahost         = var.mlz_metadatahost
  mlz_clientid             = var.mlz_clientid
  mlz_clientsecret         = var.mlz_clientsecret
  mlz_objectid             = var.mlz_objectid
  deploymentname           = var.deploymentname
  saca_subid               = var.hub_subid
  saca_rgname              = module.saca-hub.saca_rg_name
  saca_vnetname            = module.saca-hub.vnet_name
  firewall_name            = module.saca-hub.saca_firewall_name
  saca_lawsname            = module.saca-hub.laws_name
  tier2_subid              = var.tier2_subid
  tier2_rgname             = var.tier2_rgname
  tier2_vnetname           = var.tier2_vnetname
  tier2_vnet_address_space = var.tier2_vnet_address_space
  subnets                  = var.tier2_subnets
  create_network_watcher   = var.tier2_create_network_watcher
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.hub
  }
  depends_on = [
    module.saca-hub,
  ]
}

/*
module "tier3" {
  for_each = var.tier3_map
  source                   = "../core/tier-3"


  tags = {
    DeploymentName = var.deploymentname
  }
}
*/
