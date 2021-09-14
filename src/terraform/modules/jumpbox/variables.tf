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
  sensitive   = true
}

variable "object_id" {
  description = "The object ID with access the keyvault to store and retrieve jumpbox credentials"
  type        = string
}

variable "admin_username" {
  description = "The username used to administer jumpboxes"
  default     = "azureuser"
  type        = string
}

variable "windows_name" {
  description = "The name of the Windows virtual machine"
  type        = string
}

variable "windows_size" {
  description = "The size of the Windows virtual machine"
  type        = string
}

variable "windows_publisher" {
  description = "The publisher of the Windows virtual machine source image"
  type        = string
}

variable "windows_offer" {
  description = "The offer of the Windows virtual machine source image"
  type        = string
}

variable "windows_sku" {
  description = "The SKU of the Windows virtual machine source image"
  type        = string
}

variable "windows_image_version" {
  description = "The version of the Windows virtual machine source image"
  type        = string
}

variable "linux_name" {
  description = "The name of the Linux virtual machine"
  type        = string
}

variable "linux_size" {
  description = "The size of the Linux virtual machine"
  type        = string
}

variable "linux_publisher" {
  description = "The publisher of the Linux virtual machine source image"
  type        = string
}

variable "linux_offer" {
  description = "The offer of the Linux virtual machine source image"
  type        = string
}

variable "linux_sku" {
  description = "The SKU of the Linux virtual machine source image"
  type        = string
}

variable "linux_image_version" {
  description = "The version of the Linux virtual machine source image"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}
