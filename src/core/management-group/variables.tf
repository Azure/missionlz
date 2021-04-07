# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#################################
# SACA Hub Configuration
#################################
variable "deploymentname" {
  description = "A name for the deployment"
  type        = string
}

variable "create_management_group_and_add_subscriptions" {
  default     = false
  type        = bool
  description = "(Optional) Create a new management group and add the subscriptions for the saca hub and tiers to it. (Default = false)"
}

variable "management_group_name" {
  type        = string
  description = "(Optional) The friendly name to give to the new Management Group. If left blank one will be generated."
  default     = ""
}

variable "saca_subid" {
  description = "Subscription ID for the deployment"
}

variable "tier0_subid" {
  description = "Subscription ID for the deployment"
}

variable "tier1_subid" {
  description = "Subscription ID for the deployment"
}

variable "tier2_subid" {
  description = "Subscription ID for the deployment"
}


