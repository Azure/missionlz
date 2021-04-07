# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#################################
# Global Configuration
#################################
variable "tf_environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
}

variable "mlz_cloud" {
  description = "The Azure Cloud to deploy to e.g. AzureCloud or AzureUSGovernment"
}

variable "mlz_tenantid" {
  description = "The Azure tenant for the deployment"
}

variable "mlz_location" {
  description = "The Azure region for most Mission LZ resources"
}

variable "mlz_metadatahost" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
}

variable "mlz_clientid" {
  description = "The account to deploy with"
}

variable "mlz_clientsecret" {
  description = "The account to deploy with"
}

#################################
# Tier 2 Configuration
#################################
variable "deploymentname" {
  description = "A name for the deployment"
}

variable "saca_subid" {
  description = "Subscription ID for the deployment"
}

variable "saca_rgname" {
  description = "Resource Group for the deployment"
}

variable "saca_vnetname" {
  description = "Virtual Network Name for the deployment"
}

variable "saca_lawsname" {
  description = "Log Analytics Workspace name for the deployment"
}

variable "saca_fwname" {
  description = "Name of the Hub Firewall"
}

variable "tier2_subid" {
  description = "Subscription ID for the deployment"
}

variable "tier2_rgname" {
  description = "Resource Group for the deployment"
}

variable "tier2_vnetname" {
  description = "Virtual Network Name for the deployment"
}

#################################
# Network configuration section
#################################
variable "tier2_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.120.0/26"]
}

variable "subnets" {
  description = "A complex object that describes subnets."
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)

    enforce_private_link_endpoint_network_policies = bool
    enforce_private_link_service_network_policies  = bool

    nsg_name = string
    nsg_rules = map(object({
      name                       = string
      priority                   = string
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))

    routetable_name = string
  }))
  default = {
    "tier2vms" = {
      name              = "tier2vms"
      address_prefixes  = ["10.0.120.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "tier2vmsnsg"
      nsg_rules = {
        "allow_ssh" = {
          name                       = "allow_ssh"
          priority                   = "100"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "22"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        },
        "allow_rdp" = {
          name                       = "allow_rdp"
          priority                   = "200"
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "3389"
          destination_port_range     = ""
          source_address_prefix      = "*"
          destination_address_prefix = ""
        }
      }

      routetable_name = "tier2vmsrt"
    }
  }
}

variable "create_network_watcher" {
  description = "Deploy a Network Watcher resource alongside this virtual network (there's a limit of one per-subscription-per-region)"
  type        = bool
  default     = false
}
