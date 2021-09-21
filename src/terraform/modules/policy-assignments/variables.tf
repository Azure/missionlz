# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "policy_id" {
  description = "The Azure policy ID for the NIST 800-53 R4 policy initiative."
  type        = string
  default     = "/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f"
}

variable "resource_group_name" {
  description = "Resource group name for policy assignment."
  type        = string
}

variable "environment" {
  description = "The Terraform backend environment e.g. public or usgovernment. It defaults to public."
  type        = string
  default     = "public"
}

variable "laws_instance_id" {
  description = "The log analytics workspace ID which will be provided to the underlying policy rules via the policy parameters."
  type        = string
}

# Full resource ID used if enabling activity diagnostic logging
variable "log_analytics_workspace_resource_id" {
  description = "The resource id of the Log Analytics Workspace"
  type        = string
}
