# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "sub_id" {
  description = "The subscription ID to deploy the Firewall into"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
}

variable "vnet_name" {
  description = "The name of the Firewall virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space to be used for the Firewall virtual network"
  type        = list(string)
}

variable "firewall_sku_name" {
  description = "SKU name of the Firewall. Possible values are AZFW_Hub and AZFW_VNet."
  type        = string
}

variable "firewall_sku" {
  description = "The SKU for Azure Firewall"
  type        = string
}

variable "client_address_space" {
  description = "The address space to be used for the Firewall subnets"
  type        = string
}

variable "firewall_client_subnet_name" {
  description = "The name of the Firewall client traffic subnet"
  type        = string
}

variable "firewall_management_subnet_name" {
  description = "The name of the Firewall management traffic subnet"
  type        = string
}

variable "firewall_name" {
  description = "The name of the Firewall"
  type        = string
}

variable "firewall_policy_name" {
  description = "The name of the firewall policy"
  type        = string
}

variable "client_ipconfig_name" {
  description = "The name of the Firewall Client IP Configuration"
  type        = string
}

variable "client_publicip_name" {
  description = "The name of the Firewall Client Public IP"
  type        = string
}

variable "management_ipconfig_name" {
  description = "The name of the Firewall Management IP Configuration"
  type        = string
}

variable "management_publicip_name" {
  description = "The name of the Firewall Management Public IP"
  type        = string
}

variable "log_analytics_workspace_resource_id" {
  description = "The resource id of the Log Analytics Workspace"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# With forced tunneling on, Configure Azure Firewall to never SNAT regardless of the destination IP address,
# use 0.0.0.0/0 as your private IP address range.
# With this configuration, Azure Firewall can never route traffic directly to the Internet.
# see: https://docs.microsoft.com/en-us/azure/firewall/snat-private-range
variable "disable_snat_ip_range" {
  description = "The address space to be used to ensure that SNAT is disabled."
  default     = ["0.0.0.0/0"]
  type        = list(any)
}
