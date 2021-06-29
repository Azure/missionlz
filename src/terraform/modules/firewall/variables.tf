# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "sub_id" {
  description = "The subscription ID to deploy the Firewall into"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
}

variable "vnet_name" {
  description = "The name of the Firewall virtual network"
}

variable "vnet_address_space" {
  description = "The address space to be used for the Firewall virtual network"
}

variable "firewall_sku" {
  description = "The SKU for Azure Firewall"
}

variable "client_address_space" {
  description = "The address space to be used for the Firewall subnets"
}

variable "firewall_client_subnet_name" {
  description = "The name of the Firewall client traffic subnet"
}

variable "firewall_management_subnet_name" {
  description = "The name of the Firewall management traffic subnet"
}

variable "firewall_name" {
  description = "The name of the Firewall"
}

variable "firewall_policy_name" {
  description = "The name of the firewall policy"
}

variable "client_ipconfig_name" {
  description = "The name of the Firewall Client IP Configuration"
}

variable "client_publicip_name" {
  description = "The name of the Firewall Client Public IP"
}

variable "management_ipconfig_name" {
  description = "The name of the Firewall Management IP Configuration"
}

variable "management_publicip_name" {
  description = "The name of the Firewall Management Public IP"
}

variable "log_analytics_workspace_resource_id" {
  description = "The resource id of the Log Analytics Workspace"
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
  type        = list
}
