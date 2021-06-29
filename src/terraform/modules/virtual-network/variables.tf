# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
}

variable "vnet_name" {
  description = "The name of the virtual network"
}

variable "vnet_address_space" {
  description = "The address space to be used for the virtual network"
}

variable "log_analytics_workspace_resource_id" {
  description = "The resource ID of the Log Analytics Workspace to log events from the virtual network"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
