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
    random = {
      source  = "hashicorp/random"
      version = "= 3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
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
  alias           = "tier0"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  subscription_id = var.tier0_subid

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
  alias           = "tier2"
  environment     = var.tf_environment
  metadata_host   = var.mlz_metadatahost
  subscription_id = var.tier2_subid

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
}

################################
### GLOBAL VARIABLES         ###
################################

locals {
  # azurerm terraform environments where Azure Firewall Premium is supported
  firewall_premium_tf_environments = ["public"]
}

################################
### STAGE 0: Scaffolding     ###
################################

resource "azurerm_resource_group" "hub" {
  provider = azurerm.hub

  location = var.mlz_location
  name     = var.hub_rgname

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_resource_group" "tier0" {
  provider = azurerm.tier0

  location = var.mlz_location
  name     = var.tier0_rgname

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_resource_group" "tier1" {
  provider = azurerm.tier1

  location = var.mlz_location
  name     = var.tier1_rgname

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_resource_group" "tier2" {
  provider = azurerm.tier2

  location = var.mlz_location
  name     = var.tier2_rgname

  tags = {
    DeploymentName = var.deploymentname
  }
}

################################
### STAGE 1: Logging         ###
################################

resource "random_id" "laws" {
  keepers = {
    resource_group = azurerm_resource_group.tier1.name
  }

  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "laws" {
  provider   = azurerm.tier1
  depends_on = [random_id.laws]

  name                = format("%.24s", lower(replace("${var.mlz_lawsname}${random_id.laws.hex}", "/[[:^alnum:]]/", "")))
  resource_group_name = var.tier1_rgname
  location            = var.mlz_location
  sku                 = "PerGB2018"
  retention_in_days   = "30"

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_log_analytics_solution" "laws_sentinel" {
  provider = azurerm.tier1
  count    = var.create_sentinel ? 1 : 0

  solution_name         = "SecurityInsights"
  location              = azurerm_resource_group.tier1.location
  resource_group_name   = azurerm_resource_group.tier1.name
  workspace_resource_id = azurerm_log_analytics_workspace.laws.id
  workspace_name        = azurerm_log_analytics_workspace.laws.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }

  tags = {
    DeploymentName = var.deploymentname
  }
}

###############################
## STAGE 2: Networking      ###
###############################

module "hub-network" {
  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub]
  source     = "../modules/hub"

  location                 = var.mlz_location
  resource_group_name      = var.hub_rgname
  vnet_name                = var.hub_vnetname
  vnet_address_space       = var.hub_vnet_address_space
  client_address_space     = var.hub_client_address_space
  management_address_space = var.hub_management_address_space

  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "firewall" {
  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network]
  source     = "../modules/firewall"

  sub_id               = var.hub_subid
  resource_group_name  = module.hub-network.resource_group_name
  location             = var.mlz_location
  vnet_name            = module.hub-network.virtual_network_name
  vnet_address_space   = module.hub-network.virtual_network_address_space
  client_address_space = var.hub_client_address_space

  firewall_name                   = var.firewall_name
  firewall_sku                    = contains(local.firewall_premium_tf_environments, lower(var.tf_environment)) ? "Premium" : "Standard"
  firewall_client_subnet_name     = module.hub-network.firewall_client_subnet_name
  firewall_management_subnet_name = module.hub-network.firewall_management_subnet_name
  firewall_policy_name            = var.firewall_policy_name

  client_ipconfig_name = var.client_ipconfig_name
  client_publicip_name = var.client_publicip_name

  management_ipconfig_name = var.management_ipconfig_name
  management_publicip_name = var.management_publicip_name

  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "spoke-network-t0" {
  providers  = { azurerm = azurerm.tier0 }
  depends_on = [azurerm_resource_group.tier0, module.hub-network, module.firewall]
  source     = "../modules/spoke"

  location = azurerm_resource_group.tier0.location

  firewall_private_ip = module.firewall.firewall_private_ip

  laws_location     = var.mlz_location
  laws_workspace_id = azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id  = azurerm_log_analytics_workspace.laws.id

  spoke_rgname             = var.tier0_rgname
  spoke_vnetname           = var.tier0_vnetname
  spoke_vnet_address_space = var.tier0_vnet_address_space
  subnets                  = var.tier0_subnets

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_virtual_network_peering" "t0-to-hub" {
  provider   = azurerm.tier0
  depends_on = [azurerm_resource_group.tier0, module.spoke-network-t0, module.hub-network, module.firewall]

  name                         = "${var.tier0_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = var.tier0_rgname
  virtual_network_name         = var.tier0_vnetname
  remote_virtual_network_id    = module.hub-network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub-to-t0" {
  provider   = azurerm.hub
  depends_on = [azurerm_resource_group.hub, module.spoke-network-t0, module.hub-network, module.firewall]

  name                         = "${var.hub_vnetname}-to-${var.tier0_vnetname}"
  resource_group_name          = var.hub_rgname
  virtual_network_name         = var.hub_vnetname
  remote_virtual_network_id    = module.spoke-network-t0.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

module "spoke-network-t1" {
  providers  = { azurerm = azurerm.tier1 }
  depends_on = [azurerm_resource_group.tier1, module.hub-network, module.firewall]
  source     = "../modules/spoke"

  location = azurerm_resource_group.tier1.location

  firewall_private_ip = module.firewall.firewall_private_ip

  laws_location     = var.mlz_location
  laws_workspace_id = azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id  = azurerm_log_analytics_workspace.laws.id

  spoke_rgname             = var.tier1_rgname
  spoke_vnetname           = var.tier1_vnetname
  spoke_vnet_address_space = var.tier1_vnet_address_space
  subnets                  = var.tier1_subnets

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_virtual_network_peering" "t1-to-hub" {
  provider   = azurerm.tier1
  depends_on = [azurerm_resource_group.tier1, module.spoke-network-t1, module.hub-network, module.firewall]

  name                         = "${var.tier1_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = var.tier1_rgname
  virtual_network_name         = var.tier1_vnetname
  remote_virtual_network_id    = module.hub-network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub-to-t1" {
  provider   = azurerm.hub
  depends_on = [azurerm_resource_group.hub, module.spoke-network-t1, module.hub-network, module.firewall]

  name                         = "${var.hub_vnetname}-to-${var.tier1_vnetname}"
  resource_group_name          = var.hub_rgname
  virtual_network_name         = var.hub_vnetname
  remote_virtual_network_id    = module.spoke-network-t1.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

module "spoke-network-t2" {
  providers  = { azurerm = azurerm.tier2 }
  depends_on = [azurerm_resource_group.tier2, module.hub-network, module.firewall]
  source     = "../modules/spoke"

  location = azurerm_resource_group.tier2.location

  firewall_private_ip = module.firewall.firewall_private_ip

  laws_location     = var.mlz_location
  laws_workspace_id = azurerm_log_analytics_workspace.laws.workspace_id
  laws_resource_id  = azurerm_log_analytics_workspace.laws.id

  spoke_rgname             = var.tier2_rgname
  spoke_vnetname           = var.tier2_vnetname
  spoke_vnet_address_space = var.tier2_vnet_address_space
  subnets                  = var.tier2_subnets

  tags = {
    DeploymentName = var.deploymentname
  }
}

resource "azurerm_virtual_network_peering" "t2-to-hub" {
  provider   = azurerm.tier2
  depends_on = [azurerm_resource_group.tier2, module.spoke-network-t2, module.hub-network, module.firewall]

  name                         = "${var.tier2_vnetname}-to-${var.hub_vnetname}"
  resource_group_name          = var.tier2_rgname
  virtual_network_name         = var.tier2_vnetname
  remote_virtual_network_id    = module.hub-network.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub-to-t2" {
  provider   = azurerm.hub
  depends_on = [azurerm_resource_group.hub, module.spoke-network-t2, module.hub-network, module.firewall]

  name                         = "${var.hub_vnetname}-to-${var.tier2_vnetname}"
  resource_group_name          = var.hub_rgname
  virtual_network_name         = var.hub_vnetname
  remote_virtual_network_id    = module.spoke-network-t2.virtual_network_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

################################
### STAGE 3: Remote Access   ###
################################

#########################################################################
### This stage is optional based on the value of `create_bastion_jumpbox`
#########################################################################

module "jumpbox-subnet" {
  count = var.create_bastion_jumpbox ? 1 : 0

  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network, module.firewall, azurerm_log_analytics_workspace.laws]
  source     = "../modules/subnet"

  name                 = var.jumpbox_subnet.name
  location             = var.mlz_location
  resource_group_name  = var.hub_rgname
  virtual_network_name = var.hub_vnetname
  address_prefixes     = var.jumpbox_subnet.address_prefixes
  service_endpoints    = lookup(var.jumpbox_subnet, "service_endpoints", [])

  enforce_private_link_endpoint_network_policies = lookup(var.jumpbox_subnet, "enforce_private_link_endpoint_network_policies", null)
  enforce_private_link_service_network_policies  = lookup(var.jumpbox_subnet, "enforce_private_link_service_network_policies", null)

  nsg_name  = var.jumpbox_subnet.nsg_name
  nsg_rules = var.jumpbox_subnet.nsg_rules

  routetable_name     = var.jumpbox_subnet.routetable_name
  firewall_ip_address = module.firewall.firewall_private_ip

  log_analytics_storage_id            = module.hub-network.log_analytics_storage_id
  log_analytics_workspace_id          = azurerm_log_analytics_workspace.laws.workspace_id
  log_analytics_workspace_location    = var.mlz_location
  log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.laws.id

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "bastion-host" {
  count = var.create_bastion_jumpbox ? 1 : 0

  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network, module.firewall, module.jumpbox-subnet]
  source     = "../modules/bastion"

  resource_group_name   = var.hub_rgname
  virtual_network_name  = var.hub_vnetname
  bastion_host_name     = var.bastion_host_name
  subnet_address_prefix = var.bastion_address_space
  public_ip_name        = var.bastion_public_ip_name
  ipconfig_name         = var.bastion_ipconfig_name

  tags = {
    DeploymentName = var.deploymentname
  }
}

module "jumpbox" {
  count = var.create_bastion_jumpbox ? 1 : 0

  providers  = { azurerm = azurerm.hub }
  depends_on = [azurerm_resource_group.hub, module.hub-network, module.firewall, module.jumpbox-subnet]
  source     = "../modules/jumpbox"

  resource_group_name  = var.hub_rgname
  virtual_network_name = var.hub_vnetname
  subnet_name          = var.jumpbox_subnet.name
  location             = var.mlz_location

  keyvault_name = var.jumpbox_keyvault_name
  object_id     = var.mlz_objectid

  windows_name          = var.jumpbox_windows_vm_name
  windows_size          = var.jumpbox_windows_vm_size
  windows_publisher     = var.jumpbox_windows_vm_publisher
  windows_offer         = var.jumpbox_windows_vm_offer
  windows_sku           = var.jumpbox_windows_vm_sku
  windows_image_version = var.jumpbox_windows_vm_version

  linux_name          = var.jumpbox_linux_vm_name
  linux_size          = var.jumpbox_linux_vm_size
  linux_publisher     = var.jumpbox_linux_vm_publisher
  linux_offer         = var.jumpbox_linux_vm_offer
  linux_sku           = var.jumpbox_linux_vm_sku
  linux_image_version = var.jumpbox_linux_vm_version

  tags = {
    DeploymentName = var.deploymentname
  }
}
