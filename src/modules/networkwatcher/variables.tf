# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
variable name_prefix {
  description = "A prefix for naming network watcher resources"
  type        = string
}

variable location {
  description = "Location for network watcher resources (only one Azure Network Watcher per-sub-per-region)"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
