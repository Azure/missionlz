# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "name" {
  description = "The name of the subnet"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the subnet's resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the subnet's virtual network"
  type        = string
}

variable "address_prefixes" {
  description = "The subnet address prefixes"
  type        = list(string)
}

variable "service_endpoints" {
  description = "The service endpoints to optimize for this subnet"
  type        = list(string)
}

variable "enforce_private_link_endpoint_network_policies" {
  description = "Enforce Private Link Endpoints"
  type        = bool
}

variable "enforce_private_link_service_network_policies" {
  description = "Enforce Private Link Service"
  type        = bool
}

variable "nsg_name" {
  description = "The name of the subnet's virtual network"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "nsg_rules" {
  description = "A collection of azurerm_network_security_rule"
  type = map(object({
    name                       = string
    priority                   = string
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
}

variable "routetable_name" {
  description = "The name of the subnet's route table"
  type        = string
}

variable "firewall_ip_address" {
  description = "The IP Address of the Firewall"
  type        = string
}

variable "log_analytics_storage_id" {
  description = "The id of the storage account that stores log analytics diagnostic logs"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The id of the log analytics workspace"
  type        = string
}

variable "log_analytics_workspace_location" {
  description = "The location of the log analytics workspace"
  type        = string
}

variable "log_analytics_workspace_resource_id" {
  description = "The resource id of the log analytics workspace"
  type        = string
}

variable "flow_log_retention_in_days" {
  description = "The number of days to retain flow log data"
  default     = "7"
  type        = number
}
