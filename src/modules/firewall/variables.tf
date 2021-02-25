# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
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

variable "firewall_address_space" {
  description = "The address space to be used for the Firewall subnets"
}

variable "firewall_subnet_name" {
  description = "The name of the Firewall subnet"
}

variable "saca_fwname" {
  description = "The name of the Firewall"
}

variable "firewall_ipconfig_name" {
  description = "The name of the Firewall IP Configuration"
}

variable "public_ip_name" {
  description = "The name of the Firewall Public IP"
}

variable "log_analytics_workspace_id" {
  description = "The id of the Log Analytics Workspace"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
