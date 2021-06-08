# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "resource_group_name" {
  description = "The name of the resource group the virtual machine resides in"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network the virtual machine resides in"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet the virtual machine resides in"
  type        = string
}

variable "name" {
  description = "The name of the virtual machine"
  type        = string
}

variable "size" {
  description = "The size of the virtual machine"
  type        = string
}

variable "admin_username" {
  description = "The admin username of the virtual machine"
  type        = string
}

variable "admin_password" {
  description = "The admin password of the virtual machine"
  type        = string
}

variable "publisher" {
  description = "The publisher of the virtual machine source image"
  type        = string
}

variable "offer" {
  description = "The offer of the virtual machine source image"
  type        = string
}

variable "sku" {
  description = "The SKU of the virtual machine source image"
  type        = string
}

variable "image_version" {
  description = "The version of the virtual machine source image"
  type        = string
}
