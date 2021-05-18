# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "resource_group_name" {
  description = "The name of the resource group the jumpbox resides in"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network the jumpbox resides in"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet the jumpbox resides in"
  type        = string
}

variable "location" {
  description = "The region to deploy the jumpbox resides into"
  type        = string
}

variable "keyvault_name" {
  description = "The name of the keyvault to store jumpbox credentials in"
  type        = string
}

variable "tenant_id" {
  description = "The tenant ID of the keyvault to store jumpbox credentials in"
  type        = string
}

variable "object_id" {
  description = "The object ID with access the keyvault to store and retrieve jumpbox credentials"
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
