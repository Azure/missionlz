# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_resource_group_policy_assignment" "policy_assign" {
  name                 = "NIST Assignment - ${data.azurerm_resource_group.rg.name}"
  resource_group_id    = data.azurerm_resource_group.rg.id
  policy_definition_id = var.policy_id
  location             = data.azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
  # Define parameters for value template file directed to environment
  parameters = templatefile("${path.module}/nist-parameter-values/${var.environment}.json.tmpl", {
    laws_instance_id = var.laws_instance_id
  })
}
