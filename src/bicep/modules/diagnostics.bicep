/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionDiagnosticsLogs array
param bastionDiagnosticsMetrics array
param deployBastion bool
param deploymentNameSuffix string
param deployNetworkWatcherTrafficAnalytics bool
param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param keyVaultDiagnosticLogs array
param keyVaultDiagnosticMetrics array
param keyVaultName string
param location string
param logAnalyticsWorkspaceResourceId string
param networkInterfaceDiagnosticsMetrics array
param networkInterfaceResourceIds array
param networkWatcherFlowLogsRetentionDays int
param networkWatcherFlowLogsType string
param networkWatcherResourceId string
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param resourceGroupNames array
param serviceToken string
param storageAccountResourceIds array
param supportedClouds array
param tiers array

var hub = (filter(tiers, tier => tier.name == 'hub'))[0]
var hubResourceGroupName = filter(resourceGroupNames, name => contains(name, 'hub'))[0]
var operations = first(filter(tiers, tier => tier.name == 'operations'))
var operationsResourceGroupName = filter(resourceGroupNames, name => contains(name, 'operations'))[0]
var publicIPAddresses = union([
  {
    name: hub.namingConvention.azureFirewallClientPublicIPAddress
    diagName: hub.namingConvention.azureFirewallClientPublicIPAddressDiagnosticSetting
  }
  {
    name: hub.namingConvention.azureFirewallManagementPublicIPAddress
    diagName: hub.namingConvention.azureFirewallManagementPublicIPAddressDiagnosticSetting
  }
], deployBastion ? [
  {
    name: hub.namingConvention.bastionHostPublicIPAddress
    diagName: hub.namingConvention.bastionHostPublicIPAddressDiagnosticSetting
  }
] : [])

module activityLogDiagnosticSettings 'activity-log-diagnostic-settings.bicep' = [for (tier, i) in tiers: if (tier.deployUniqueResources) {
  name: 'deploy-activity-diags-${tier.name}-${deploymentNameSuffix}'
  scope: subscription(tier.subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
}]

module logAnalyticsWorkspaceDiagnosticSetting 'log-analytics-diagnostic-setting.bicep' = {
  name: 'deploy-law-diag-${deploymentNameSuffix}'
  scope: resourceGroup(operations.subscriptionId, operationsResourceGroupName)
  params: {
    diagnosticStorageAccountName: split(storageAccountResourceIds[1], '/')[8]
    logAnalyticsWorkspaceDiagnosticSettingName: operations.namingConvention.logAnalyticsWorkspaceDiagnosticSetting
    logAnalyticsWorkspaceName: split(logAnalyticsWorkspaceResourceId, '/')[8]
    supportedClouds: supportedClouds
  }
}

module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostics.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-nsg-diags-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tier.namingConvention.networkWatcherFlowLogsNetworkSecurityGroup
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: tier.nsgDiagLogs
    networkSecurityGroupDiagnosticSettingName: tier.namingConvention.networkSecurityGroupDiagnosticSetting
    networkSecurityGroupName: tier.namingConvention.networkSecurityGroup
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherName: empty(networkWatcherResourceId) ? hub.namingConvention.networkWatcher : split(networkWatcherResourceId, '/')[8]
    networkWatcherResourceGroupName: empty(networkWatcherResourceId) ? hubResourceGroupName : split(networkWatcherResourceId, '/')[4]
    storageAccountResourceId: storageAccountResourceIds[i]
    tiername: tier.name
  }
}]

@batchSize(1)
module virtualNetworkDiagnostics '../modules/virtual-network-diagnostics.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-vnet-diags-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tier.namingConvention.networkWatcherFlowLogsVirtualNetwork
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: tier.vnetDiagLogs
    logStorageAccountResourceId: storageAccountResourceIds[i]
    metrics: tier.vnetDiagMetrics
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherName: empty(networkWatcherResourceId) ? hub.namingConvention.networkWatcher : split(networkWatcherResourceId, '/')[8]
    networkWatcherResourceGroupName: empty(networkWatcherResourceId) ? hubResourceGroupName : split(networkWatcherResourceId, '/')[4]
    tiername: tier.name
    virtualNetworkDiagnosticSettingName: tier.namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkName: tier.namingConvention.virtualNetwork
  }
}]

module publicIpAddressDiagnostics '../modules/public-ip-address-diagnostics.bicep' = [for publicIPAddress in publicIPAddresses: {
  name: 'deploy-pip-diags-${split(publicIPAddress.name, '-')[2]}-${split(publicIPAddress.name, '-')[3]}-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    hubStorageAccountResourceId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    publicIPAddressDiagnosticSettingName: publicIPAddress.diagName
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
    publicIPAddressName: publicIPAddress.name
  }
}]

module firewallDiagnostics '../modules/firewall-diagnostics.bicep' = {
  name: 'deploy-afw-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    firewallDiagnosticSettingsName: hub.namingConvention.azureFirewallDiagnosticSetting
    firewallName: hub.namingConvention.azureFirewall
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[0]
    metrics: firewallDiagnosticsMetrics
  }
}

module keyVaultDiagnostics '../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: replace(hub.namingConvention.keyVaultDiagnosticSetting, serviceToken, '')
    keyVaultName: keyVaultName
    keyVaultStorageAccountId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
    metrics: keyVaultDiagnosticMetrics
  }
}

module bastionDiagnostics '../modules/bastion-diagnostics.bicep' = if (deployBastion) {
  name: 'deploy-bastion-diags-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    diagnosticSettingName: replace(hub.namingConvention.bastionHostPublicIPAddressDiagnosticSetting, serviceToken, '')
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: bastionDiagnosticsLogs
    metrics: bastionDiagnosticsMetrics
    name: hub.namingConvention.bastionHost
    storageAccountResourceId: storageAccountResourceIds[0]
  }
}

module networkInterfaceDiagnostics '../modules/network-interface-diagnostics.bicep' = [for (networkInterfaceResourceId, i) in networkInterfaceResourceIds: {
  name: 'deploy-nic-diags-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(networkInterfaceResourceId, '/')[2], split(networkInterfaceResourceId, '/')[4])
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: []
    metrics: networkInterfaceDiagnosticsMetrics
    networkInterfaceResourceId: networkInterfaceResourceId
    storageAccountResourceIds: storageAccountResourceIds
    tiers: tiers
  }
}]
