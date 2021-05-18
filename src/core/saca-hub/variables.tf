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

variable "client_address_space" {
  description = "The address space to be used for the Firewall virtual network."
  default     = "10.0.100.0/26"
  type        = string
}

variable "management_address_space" {
  description = "The address space to be used for the Firewall virtual network subnet used for management traffic."
  default     = "10.0.100.64/26"
  type        = string
}

variable "firewall_name" {
  description = "Name of the Hub Firewall"
  default     = "mlzDemoFirewall"
}

variable "client_ipconfig_name" {
  description = "The name of the Firewall Client IP Configuration"
  default     = "mlzDemoFWClientIpCfg"
}

variable "client_publicip_name" {
  description = "The name of the Firewall Client Public IP"
  default     = "mlzDemoFWClientPip"
}

variable "management_ipconfig_name" {
  description = "The name of the Firewall Management IP Configuration"
  default     = "mlzDemoFWMgmtIpCfg"
}

variable "management_publicip_name" {
  description = "The name of the Firewall Management Public IP"
  default     = "mlzDemoFWMgmtPip"
}

variable "management_routetable_name" {
  description = "The name of the route table applied to the management subnet"
  default     = "mlzDemoFirewallMgmtRT"
}

variable "create_network_watcher" {
  description = "Deploy a Network Watcher resource alongside this virtual network (there's a limit of one per-subscription-per-region)"
  type        = bool
  default     = false
}

#################################
# Bastion Host Configuration
#################################

variable "bastion_host_name" {
  description = "The name of the Bastion Host"
  default     = "mlzDemoBastionHost"
  type        = string
}

variable "bastion_address_space" {
  description = "The address space to be used for the Bastion Host subnet (must be /27 or larger)."
  default     = "10.0.100.128/27"
  type        = string
}

variable "bastion_public_ip_name" {
  description = "The name of the Bastion Host Public IP"
  default     = "mlzDemoBastionHostPip"
  type        = string
}

variable "bastion_ipconfig_name" {
  description = "The name of the Bastion Host IP Configuration"
  default     = "mlzDemoBastionHostIpCfg"
  type        = string
}
