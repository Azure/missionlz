# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "resource_group_name" {
  description = "The name of the resource group the Bastion Host resides in"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network the Bastion Host resides in"
  type        = string
}

variable "bastion_host_name" {
  description = "The name of the Bastion Host"
  type        = string
}

variable "subnet_address_prefix" {
  description = "The address prefix for the Bastion Host (must be a /27 or larger)"
  type        = string
}

variable "public_ip_name" {
  description = "The name of the Bastion Host public IP address resource"
  type        = string
}

variable "ipconfig_name" {
  description = "The name of the Bastion Host IP configuration resource"
  type        = string
}

variable "tags" {
  description = "A mapping of tags which should be assigned to the resource."
  type        = map(string)
}
