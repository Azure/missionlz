# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "resource_group_name" {
  description = "The name of the resource group the Bastion Host resides in"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network the Bastion Host resides in"
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

variable "bastion_host_ipconfig_name" {
  description = "The name of the Bastion Host IP configuration resource"
  type        = string
}

variable "tags" {
  type = map(string)
}