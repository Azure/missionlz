# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
data "azurerm_resource_group" "hub" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "hub" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.hub.name
}

data "azurerm_subnet" "firewall" {
  name                 = var.firewall_subnet_name
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name  = data.azurerm_resource_group.hub.name
}

resource "azurerm_public_ip" "firewall" {
  name                = var.public_ip_name
  location            = data.azurerm_resource_group.hub.location
  resource_group_name = data.azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = var.saca_fwname
  location            = data.azurerm_resource_group.hub.location
  resource_group_name = data.azurerm_resource_group.hub.name
  sku_tier            = "Premium"
  tags                = var.tags

  ip_configuration {
    name                 = var.firewall_ipconfig_name
    subnet_id            = data.azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "random_id" "storageaccount" {
  byte_length = 12
}

resource "azurerm_storage_account" "loganalytics" {
  name                      = format("%.24s", lower(replace("${azurerm_firewall.firewall.name}logs${random_id.storageaccount.id}", "/[[:^alnum:]]/", "")))
  resource_group_name       = data.azurerm_resource_group.hub.name
  location                  = data.azurerm_resource_group.hub.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  tags                      = var.tags
}

locals {
  firewall_log_categories  = ["AzureFirewallApplicationRule", "AzureFirewallNetworkRule"]
  public_ip_log_categories = ["DDoSProtectionNotifications", "DDoSMitigationFlowLogs", "DDoSMitigationReports"]
}

resource "azurerm_monitor_diagnostic_setting" "firewall-diagnostics" {
  name                       = "${azurerm_firewall.firewall.name}-diagnostics"
  target_resource_id         = azurerm_firewall.firewall.id
  storage_account_id         = azurerm_storage_account.loganalytics.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = local.firewall_log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "publicip-diagnostics" {
  name                       = "${azurerm_public_ip.firewall.name}-diagnostics"
  target_resource_id         = azurerm_public_ip.firewall.id
  storage_account_id         = azurerm_storage_account.loganalytics.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    for_each = local.public_ip_log_categories
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"
    retention_policy {
      enabled = false
    }
  }
}
