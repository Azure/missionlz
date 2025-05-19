/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionDiagnosticsLogs array
param bastionDiagnosticsMetrics array
param delimiter string
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
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param resourceGroupNames array
param storageAccountResourceIds array
param supportedClouds array
param tiers array

var hub = (filter(tiers, tier => tier.name == 'hub'))[0]
var hubResourceGroupName = filter(resourceGroupNames, name => contains(name, 'hub'))[0]
var networkSecurityGroups = union(networkSecurityGroups_Tiers, networkSecurityGroup_Bastion)
var networkSecurityGroups_Tiers = [for (tier, i) in tiers: {
  diagnosticLogs: tiers[i].nsgDiagLogs
  diagnosticSettingName: tiers[i].namingConvention.networkSecurityGroupDiagnosticSetting
  flowLogsName: tiers[i].namingConvention.networkWatcherFlowLogsNetworkSecurityGroup
  name: tiers[i].namingConvention.networkSecurityGroup
  namingConvention: tiers[i].namingConvention
  resourceGroupName: resourceGroupNames[i]
  storageAccountResourceId: storageAccountResourceIds[i]
  subscriptionId: tiers[i].subscriptionId
  tierName: tiers[i].name
}]
var networkSecurityGroup_Bastion = deployBastion ? [
  {
    diagnosticLogs: hub.nsgDiagLogs
    diagnosticSettingName: hub.namingConvention.bastionHostNetworkSecurityGroupDiagnosticSetting
    flowLogsName: '${hub.namingConvention.networkWatcherFlowLogsNetworkSecurityGroup}${delimiter}bastion'
    name: hub.namingConvention.bastionHostNetworkSecurityGroup
    namingConvention: hub.namingConvention
    resourceGroupName: hubResourceGroupName
    storageAccountResourceId: storageAccountResourceIds[0]
    subscriptionId: hub.subscriptionId
    tierName: 'hub${delimiter}bas'
  }
] : []
var operations = first(filter(tiers, tier => tier.name == 'operations'))
var operationsResourceGroupName = filter(resourceGroupNames, name => contains(name, 'operations'))[0]
var publicIPAddresses = union([
  {
    name: '${hub.namingConvention.azureFirewallPublicIPAddress}${delimiter}client'
    diagName: '${hub.namingConvention.azureFirewallPublicIPAddressDiagnosticSetting}${delimiter}client'
  }
  {
    name: '${hub.namingConvention.azureFirewallPublicIPAddress}${delimiter}management'
    diagName: '${hub.namingConvention.azureFirewallPublicIPAddressDiagnosticSetting}${delimiter}management'
  }
], deployBastion ? [
  {
    name: hub.namingConvention.bastionHostPublicIPAddress
    diagName: hub.namingConvention.bastionHostPublicIPAddressDiagnosticSetting
  }
] : [])

@batchSize(1)
module activityLogDiagnosticSettings 'activity-log-diagnostic-settings.bicep' = [for (tier, i) in tiers: {
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

@batchSize(1)
module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostics.bicep' = [for (nsg, i) in networkSecurityGroups: {
  name: 'deploy-nsg-diags-${nsg.tierName}-${deploymentNameSuffix}'
  scope: resourceGroup(nsg.subscriptionId, nsg.resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: nsg.flowLogsName
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: nsg.diagnosticLogs
    networkSecurityGroupDiagnosticSettingName: nsg.diagnosticSettingName
    networkSecurityGroupName: nsg.name
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    storageAccountResourceId: nsg.storageAccountResourceId
    tiername: nsg.tierName
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
    tiername: tier.name
    virtualNetworkDiagnosticSettingName: tier.namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkName: tier.namingConvention.virtualNetwork
  }
}]

module publicIpAddressDiagnostics '../modules/public-ip-address-diagnostics.bicep' = [for (publicIPAddress, i) in publicIPAddresses: {
  name: 'deploy-pip-diags-${i}-${deploymentNameSuffix}'
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
    keyVaultDiagnosticSettingName: hub.namingConvention.keyVaultDiagnosticSetting
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
    diagnosticSettingName: hub.namingConvention.bastionHostDiagnosticSetting
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
