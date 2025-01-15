# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "location" {
  description = "The region for spoke network deployment"
  type        = string
}

variable "laws_location" {
  description = "Log Analytics Workspace location"
  type        = string
}

variable "laws_workspace_id" {
  description = "Log Analytics Workspace workspace ID"
  type        = string
}

variable "laws_resource_id" {
  description = "Log Analytics Workspace Azure Resource ID"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of the Firewall"
  type        = string
}

variable "spoke_rgname" {
  description = "Resource Group for the spoke network deployment"
  type        = string
}

variable "spoke_vnetname" {
  description = "Virtual Network Name for the spoke network deployment"
  type        = string
}

#################################
# Network configuration section
#################################
variable "spoke_vnet_address_space" {
  description = "Address space prefixes for the spoke network"
  type        = list(string)
}

variable "subnets" {
  description = "A complex object that describes subnets for the spoke network"
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
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}
