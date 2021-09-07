# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#################################
# Global Configuration
#################################

variable "tf_environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
}

variable "deploymentname" {
  description = "A name for the deployment"
}

variable "mlz_location" {
  description = "The Azure region for most Mission LZ resources"
}

variable "mlz_metadatahost" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
}

variable "mlz_objectid" {
  description = "The account to deploy with"
}

#################################
# Hub Configuration
#################################

variable "hub_subid" {
  description = "Subscription ID for the deployment"
}

variable "hub_rgname" {
  description = "Resource Group for the deployment"
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the deployment"
}

variable "firewall_private_ip" {
  description = "Firewall IP to bind network to"
}

#################################
# Tier 1 Configuration
#################################

variable "tier1_subid" {
  description = "Subscription ID for the deployment"
}

variable "laws_name" {
  description = "Log Analytics Workspace Name for the deployment"
}

variable "laws_rgname" {
  description = "The RG that laws was deployed to."
}

#################################
# Tier 3 Configuration
#################################
variable "tier3_subid" {
  description = "Subscription ID for the deployment"
}

variable "tier3_rgname" {
  description = "Resource Group for the deployment"
}

variable "tier3_vnetname" {
  description = "Virtual Network Name for the deployment"
}

variable "tier3_vnet_address_space" {
  description = "Address space prefixes list of strings"
  type        = list(string)
  default     = ["10.0.125.0/26"]
}

variable "tier3_subnets" {
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
    "tier3vms" = {
      name              = "tier3vms"
      address_prefixes  = ["10.0.125.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "tier3vmsnsg"
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

      routetable_name = "tier3vmsrt"
    }
  }
}
