# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
data "azurerm_resource_group" "hub" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "hub" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.hub.name
}

data "azurerm_subnet" "fw_client_sn" {
  name                 = var.firewall_client_subnet_name
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name  = data.azurerm_resource_group.hub.name
}

data "azurerm_subnet" "fw_mgmt_sn" {
  name                 = var.firewall_management_subnet_name
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name  = data.azurerm_resource_group.hub.name
}

resource "azurerm_public_ip" "fw_client_pip" {
  name                = var.client_publicip_name
  location            = data.azurerm_resource_group.hub.location
  resource_group_name = data.azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_public_ip" "fw_mgmt_pip" {
  name                = var.management_publicip_name
  location            = data.azurerm_resource_group.hub.location
  resource_group_name = data.azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "firewallpolicy" {
  name                     = var.firewall_policy_name
  resource_group_name      = data.azurerm_resource_group.hub.name
  location                 = data.azurerm_resource_group.hub.location
  sku                      = var.firewall_sku
  threat_intelligence_mode = "Alert"
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = data.azurerm_resource_group.hub.location
  resource_group_name = data.azurerm_resource_group.hub.name
  sku_tier            = var.firewall_sku
  private_ip_ranges   = var.disable_snat_ip_range
  firewall_policy_id  = azurerm_firewall_policy.firewallpolicy.id
  tags                = var.tags

  ip_configuration {
    name                 = var.client_ipconfig_name
    subnet_id            = data.azurerm_subnet.fw_client_sn.id
    public_ip_address_id = azurerm_public_ip.fw_client_pip.id
  }

  management_ip_configuration {
    name                 = var.management_ipconfig_name
    subnet_id            = data.azurerm_subnet.fw_mgmt_sn.id
    public_ip_address_id = azurerm_public_ip.fw_mgmt_pip.id
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
  name                       = "${azurerm_firewall.firewall.name}-fw-diagnostics"
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
  name                       = "${azurerm_public_ip.fw_client_pip.name}-pip-diagnostics"
  target_resource_id         = azurerm_public_ip.fw_client_pip.id
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
