# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

output "virtual_network_id" {
  description = "The id of the virtual network"
  value       = module.spoke-network.virtual_network_id
}
