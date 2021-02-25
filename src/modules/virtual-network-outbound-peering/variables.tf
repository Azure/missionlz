# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
variable "source_rg_name" {
  description = "Resource Group name for the source end of the network peer"
}

variable "source_vnet_name" {
  description = "Virtual Network name for the source end of the network peer"
}

variable "destination_subscription_id" {
  description = "Subscription ID for the target end of the VNET peer"
}

variable "destination_rg_name" {
  description = "Resource Group name for the target end of the VNET peer"
}

variable "destination_vnet_name" {
  description = "Virtual Network name for the target end of the VNET peer"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}