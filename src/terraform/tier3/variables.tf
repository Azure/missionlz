# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#################################
# Global Configuration
#################################

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
  type        = string
  default     = "public"
}

variable "metadata_host" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
  type        = string
  default     = "management.azure.com"
}

variable "location" {
  description = "The Azure region for most Mission LZ resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "A map of key value pairs to apply as tags to resources provisioned in this deployment"
  type        = map(string)
  default = {
    "DeploymentType" : "MissionLandingZoneTF"
  }
}

#################################
# Hub Configuration
#################################

variable "hub_subid" {
  description = "Subscription ID for the Hub deployment"
  type        = string
}

variable "hub_rgname" {
  description = "Resource Group for the Hub deployment"
  type        = string
}

variable "hub_vnetname" {
  description = "Virtual Network Name for the Hub deployment"
  type        = string
}

variable "firewall_private_ip" {
  description = "Firewall IP to bind network to"
  type        = string
}

#################################
# Tier 1 Configuration
#################################

variable "tier1_subid" {
  description = "Subscription ID for the Tier 1 deployment"
  type        = string
}

variable "laws_name" {
  description = "Log Analytics Workspace Name for the deployment"
  type        = string
}

variable "laws_rgname" {
  description = "The resource group that Log Analytics Workspace was deployed to"
  type        = string
}

#################################
# Tier 3 Configuration
#################################
variable "tier3_subid" {
  description = "Subscription ID for this Tier 3 deployment"
  type        = string
}

variable "tier3_rgname" {
  description = "Resource Group for this Tier 3 deployment"
  type        = string
  default     = "tier3-rg"
}

variable "tier3_vnetname" {
  description = "Virtual Network Name for this Tier 3 deployment"
  type        = string
  default     = "tier3-vnet"
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
    "tier3subnet" = {
      name              = "tier3Subnet"
      address_prefixes  = ["10.0.125.0/27"]
      service_endpoints = ["Microsoft.Storage"]

      enforce_private_link_endpoint_network_policies = false
      enforce_private_link_service_network_policies  = false

      nsg_name = "tier3SubnetNsg"
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

      routetable_name = "tier3RouteTable"
    }
  }
}
