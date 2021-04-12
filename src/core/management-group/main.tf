# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#Create the management group and apply to subscriptions

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "random" {
}


resource "random_id" "mgmt-group" {
  byte_length = 12
}

locals {
  #If the user didn't give us a management group name then generate one
  management_group_name = (var.management_group_name != "" ? var.management_group_name : format("%.24s", lower(replace("mlz-mg-${random_id.mgmt-group.hex}", "/[[:^alnum:]]/", ""))))

  subscription_ids_to_add_to_mgmt_group = [
    var.saca_subid,
    var.tier0_subid,
    var.tier1_subid,
    var.tier2_subid
  ]
}

resource "azurerm_management_group" "mg" {
  count            = var.create_management_group_and_add_subscriptions == true ? 1 : 0
  display_name     = local.management_group_name
  subscription_ids = local.subscription_ids_to_add_to_mgmt_group
}

