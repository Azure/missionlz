# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.69.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

variable "subscription_id" {
  type = string
  description = "The subscription that contains the Log Analytics Workspace and to deploy the Sentinel solution into"
}

variable location {
  type = string
  description = "The Azure region to deploy the Sentinel solution"
}

variable "resource_group_name" {
  type = string
  description = "The name of the resource group that will contain the Sentinel solution"
}

variable "workspace_name" {
  type = string
  description = "The name of the Log Analytics Workspace that will link to the Sentinel solution"
}

variable "workspace_resource_id" {
  type = string
  description = "The resource id of the Log Analytics Workspace that will link to the Sentinel solution"
}


resource "azurerm_log_analytics_solution" "laws_sentinel" {
  solution_name         = "SecurityInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_name        = var.workspace_name
  workspace_resource_id = var.workspace_resource_id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}