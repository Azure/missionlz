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
    key_vault {
      purge_soft_delete_on_destroy = true
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
  client_address_space     = var.client_address_space
  management_address_space = var.management_address_space
  routetable_name          = var.management_routetable_name

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
  depends_on                      = [module.saca-hub-network]
  source                          = "../../modules/firewall"
  location                        = var.mlz_location
  resource_group_name             = module.saca-hub-network.resource_group_name
  vnet_name                       = module.saca-hub-network.virtual_network_name
  vnet_address_space              = module.saca-hub-network.virtual_network_address_space
  firewall_sku                    = contains(local.firewall_premium_tf_environments, lower(var.tf_environment)) ? "Premium" : "Standard"
  firewall_client_subnet_name     = module.saca-hub-network.firewall_client_subnet_name
  firewall_management_subnet_name = module.saca-hub-network.firewall_management_subnet_name
  client_address_space            = var.client_address_space
  firewall_name                   = var.firewall_name
  client_ipconfig_name            = var.client_ipconfig_name
  client_publicip_name            = var.client_publicip_name
  management_ipconfig_name        = var.management_ipconfig_name
  management_publicip_name        = var.management_publicip_name

  log_analytics_workspace_id = module.saca-hub-network.log_analytics_workspace_id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "bastion-host" {
  count      = var.create_bastion_jumpbox ? 1 : 0
  depends_on = [module.saca-hub-network]
  source     = "../../modules/bastion"

  resource_group_name   = azurerm_resource_group.hub.name
  virtual_network_name  = var.saca_vnetname
  bastion_host_name     = var.bastion_host_name
  subnet_address_prefix = var.bastion_address_space
  public_ip_name        = var.bastion_public_ip_name
  ipconfig_name         = var.bastion_ipconfig_name

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "jumpbox-subnet" {
  count      = var.create_bastion_jumpbox ? 1 : 0
  depends_on = [module.saca-hub-network, module.saca-firewall]
  source     = "../../modules/subnet"

  name                 = var.jumpbox_subnet.name
  location             = var.mlz_location
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = var.saca_vnetname
  address_prefixes     = var.jumpbox_subnet.address_prefixes
  service_endpoints    = lookup(var.jumpbox_subnet, "service_endpoints", [])

  enforce_private_link_endpoint_network_policies = lookup(var.jumpbox_subnet, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(var.jumpbox_subnet, "enforce_private_link_service_network_policies", null)

  nsg_name  = var.jumpbox_subnet.nsg_name
  nsg_rules = var.jumpbox_subnet.nsg_rules

  routetable_name     = var.jumpbox_subnet.routetable_name
  firewall_ip_address = module.saca-firewall.firewall_public_ip

  log_analytics_storage_id   = module.saca-hub-network.log_analytics_storage_id
  log_analytics_workspace_id = module.saca-hub-network.log_analytics_workspace_id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "jumpbox" {
  count      = var.create_bastion_jumpbox ? 1 : 0
  depends_on = [module.saca-hub-network, module.jumpbox-subnet]
  source     = "../../modules/jumpbox"

  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = var.saca_vnetname
  subnet_name          = var.jumpbox_subnet.name
  location             = azurerm_resource_group.hub.location

  keyvault_name = var.jumpbox_keyvault_name
  tenant_id     = var.mlz_tenantid
  object_id     = var.mlz_objectid

  name          = var.jumpbox_vm_name
  size          = var.jumpbox_vm_size
  publisher     = var.jumpbox_vm_publisher
  offer         = var.jumpbox_vm_offer
  sku           = var.jumpbox_vm_sku
  image_version = var.jumpbox_vm_version
}
