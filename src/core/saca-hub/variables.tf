# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#################################
# Global Configuration
#################################

variable "tf_environment" {
  description = "The Terraform backend environment e.g. public or usgovernment"
}

variable "mlz_cloud" {
  description = "The Azure Cloud to deploy to e.g. AzureCloud or AzureUSGovernment"
}

variable "mlz_tenantid" {
  description = "The Azure tenant for the deployment"
}

variable "mlz_location" {
  description = "The Azure region for most Mission LZ resources"
}

variable "mlz_metadatahost" {
  description = "The metadata host for the Azure Cloud e.g. management.azure.com"
}

variable "mlz_clientid" {
  description = "The account to deploy with"
}

variable "mlz_clientsecret" {
  description = "The account to deploy with"
}

#################################
# SACA Hub Configuration
#################################
variable "deploymentname" {
  description = "A name for the deployment"
}

variable "saca_subid" {
  description = "Subscription ID for the deployment"
}

variable "saca_rgname" {
  description = "Resource Group for the deployment"
}

variable "saca_vnetname" {
  description = "Virtual Network Name for the deployment"
}

variable "saca_lawsname" {
  description = "Log Analytics Workspace Name for the deployment"
}

variable "vnet_address_space" {
  description = "The address space to be used for the virtual network."
  default     = ["10.0.100.0/24"]
  type        = list(string)
}

#################################
# Firewall configuration section
#################################

variable "firewall_address_space" {
  description = "The address space to be used for the Firewall virtual network."
  default     = "10.0.100.0/26"
  type        = string
}

variable "saca_fwname" {
  description = "Name of the Hub Firewall"
  default     = "mlzDemoFirewall"
}

variable "firewall_ipconfig_name" {
  description = "The name of the Firewall IP Configuration"
  default     = "mlzDemoFirewallIpConfiguration"
}

variable "public_ip_name" {
  description = "The name of the Firewall Public IP"
  default     = "mlzDemoFirewallPip"
}

variable "create_network_watcher" {
  description = "Deploy a Network Watcher resource alongside this virtual network (there's a limit of one per-subscription-per-region)"
  type        = bool
  default     = false
}
