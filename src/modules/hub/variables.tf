# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
}

variable "vnet_name" {
  description = "The name of the virtual network"
}

variable "vnet_address_space" {
  description = "The address space to be used for the virtual network."
  default     = []
  type        = list(string)
}

variable "firewall_address_space" {
  description = "The address space to be used for the Firewall virtual network."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name used for the Log Analytics Workspace (must be globally unique)."
  type        = string
}

variable "log_analytics_workspace_sku" {
  description = "The SKU used for the Log Analytics Workspace."
  type        = string
}

variable "log_analytics_workspace_retention_in_days" {
  description = "The number of days to retain logs in the Log Analytics Workspace."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}
