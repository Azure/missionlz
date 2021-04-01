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

variable "management_group_name" {
  type        = string
  description = "(Optional) The friendly name to give to the new Management Group. If left blank one will be generated."
  default     = ""
}


variable "saca_subid" {
  description = "Subscription ID for the deployment"
}