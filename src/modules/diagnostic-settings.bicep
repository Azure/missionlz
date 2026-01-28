/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionDiagnosticsLogs array
param bastionDiagnosticsMetrics array
param blobDiagnosticsLogs array
param blobDiagnosticsMetrics array
param delimiter string
param deployBastion bool
param deploymentNameSuffix string
param deployNetworkWatcherTrafficAnalytics bool
param fileDiagnosticsLogs array
param fileDiagnosticsMetrics array
param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param keyVaultDiagnosticLogs array
param keyVaultDiagnosticMetrics array
param keyVaults array
param location string
param logAnalyticsWorkspaceResourceId string
param networkInterfaceDiagnosticsMetrics array
param networkInterfaceResourceIds array
param networkWatcherFlowLogsRetentionDays int
param networkWatcherFlowLogsType string
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param queueDiagnosticsLogs array
param queueDiagnosticsMetrics array
param storageAccountDiagnosticsLogs array
param storageAccountDiagnosticsMetrics array
param storageAccountResourceIds array
param supportedClouds array
param tableDiagnosticsLogs array
param tableDiagnosticsMetrics array
param tiers array
param tokens object

var dedupedSubscriptionIds = union(subscriptionIds, [])
var hub = filter(tiers, tier => tier.name == 'hub')[0]
var networkSecurityGroups = union(networkSecurityGroups_Tiers, networkSecurityGroup_Bastion)
var networkSecurityGroups_Tiers = [for (tier, i) in tiers: {
  diagnosticLogs: tier.nsgDiagLogs
  diagnosticSettingName: replace(tier.namingConvention.networkSecurityGroupDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
  flowLogsName: replace(tier.namingConvention.networkWatcherFlowLogsNetworkSecurityGroup, '${delimiter}${tokens.purpose}', '')
  name: replace(tier.namingConvention.networkSecurityGroup, '${delimiter}${tokens.purpose}', '')
  resourceGroupName: tier.resourceGroupName
  storageAccountResourceId: storageAccountResourceIds[i]
  subscriptionId: tier.subscriptionId
  tierName: tier.name
}]
var networkSecurityGroup_Bastion = deployBastion ? [
  {
    diagnosticLogs: hub.nsgDiagLogs
    diagnosticSettingName: replace(hub.namingConvention.bastionHostNetworkSecurityGroupDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    flowLogsName: replace(hub.namingConvention.networkWatcherFlowLogsNetworkSecurityGroup, tokens.purpose, 'bastion')
    name: replace(hub.namingConvention.bastionHostNetworkSecurityGroup, '${delimiter}${tokens.purpose}', '')
    resourceGroupName: hub.resourceGroupName
    storageAccountResourceId: storageAccountResourceIds[0]
    subscriptionId: hub.subscriptionId
    tierName: 'hub${delimiter}bas'
  }
] : []
var operations = filter(tiers, tier => tier.name == 'operations')[0]
var publicIPAddresses = union([
  {
    name: replace(hub.namingConvention.azureFirewallPublicIPAddress, tokens.purpose, 'client')
    diagName: replace(hub.namingConvention.azureFirewallPublicIPAddressDiagnosticSetting, tokens.purpose, 'client')
  }
  {
    name: replace(hub.namingConvention.azureFirewallPublicIPAddress, tokens.purpose, 'mgmt')
    diagName: replace(hub.namingConvention.azureFirewallPublicIPAddressDiagnosticSetting, tokens.purpose, 'mgmt')
  }
], deployBastion ? [
  {
    name: replace(hub.namingConvention.bastionHostPublicIPAddress, '${delimiter}${tokens.purpose}', '')
    diagName: replace(hub.namingConvention.bastionHostPublicIPAddressDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
  }
] : [])
var subscriptionIds = [for tier in tiers: tier.subscriptionId]

module activityLogDiagnosticSettings 'activity-log-diagnostic-setting.bicep' = [for (subscriptionId, i) in dedupedSubscriptionIds: {
  name: 'deploy-activity-diag-${i}-${deploymentNameSuffix}'
  scope: subscription(subscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
}]

module logAnalyticsWorkspaceDiagnosticSetting 'log-analytics-diagnostic-setting.bicep' = {
  name: 'deploy-law-diag-${deploymentNameSuffix}'
  scope: resourceGroup(operations.subscriptionId, operations.resourceGroupName)
  params: {
    diagnosticStorageAccountName: split(storageAccountResourceIds[1], '/')[8]
    logAnalyticsWorkspaceDiagnosticSettingName: replace(operations.namingConvention.logAnalyticsWorkspaceDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    logAnalyticsWorkspaceName: split(logAnalyticsWorkspaceResourceId, '/')[8]
    supportedClouds: supportedClouds
  }
}

@batchSize(1)
module storageAccountDiagnosticSettings 'storage-account-diagnostic-settings.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-sa-diag-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    blobDiagnosticSettingName: replace(tier.namingConvention.storageAccountBlobDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    blobDiagnosticsLogs: blobDiagnosticsLogs
    blobDiagnosticsMetrics: blobDiagnosticsMetrics
    fileDiagnosticSettingName: replace(tier.namingConvention.storageAccountFileDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    fileDiagnosticsLogs: fileDiagnosticsLogs
    fileDiagnosticsMetrics: fileDiagnosticsMetrics
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: tier.name == 'hub' ? storageAccountResourceIds[1] : storageAccountResourceIds[0]
    queueDiagnosticSettingName: replace(tier.namingConvention.storageAccountQueueDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    queueDiagnosticsLogs: queueDiagnosticsLogs
    queueDiagnosticsMetrics: queueDiagnosticsMetrics
    storageAccountDiagnosticSettingName: replace(tier.namingConvention.storageAccountDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    storageAccountDiagnosticsLogs: storageAccountDiagnosticsLogs
    storageAccountDiagnosticsMetrics: storageAccountDiagnosticsMetrics
    storageAccountName: split(storageAccountResourceIds[i], '/')[8]
    tableDiagnosticSettingName: replace(tier.namingConvention.storageAccountTableDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    tableDiagnosticsLogs: tableDiagnosticsLogs
    tableDiagnosticsMetrics: tableDiagnosticsMetrics
  }
}]

@batchSize(1)
module networkSecurityGroupDiagnostics '../modules/network-security-group-diagnostic-setting.bicep' = [for (nsg, i) in networkSecurityGroups: {
  name: 'deploy-nsg-diag-${nsg.tierName}-${deploymentNameSuffix}'
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
module virtualNetworkDiagnostics '../modules/virtual-network-diagnostic-setting.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-vnet-diag-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: replace(tier.namingConvention.networkWatcherFlowLogsVirtualNetwork, '${delimiter}${tokens.purpose}', '')
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: tier.vnetDiagLogs
    logStorageAccountResourceId: storageAccountResourceIds[i]
    metrics: tier.vnetDiagMetrics
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    tiername: tier.name
    virtualNetworkDiagnosticSettingName: replace(tier.namingConvention.virtualNetworkDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    virtualNetworkName: replace(tier.namingConvention.virtualNetwork, '${delimiter}${tokens.purpose}', '')
  }
}]

module publicIpAddressDiagnosticSettings '../modules/public-ip-address-diagnostic-setting.bicep' = [for (publicIPAddress, i) in publicIPAddresses: {
  name: 'deploy-pip-diag-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hub.resourceGroupName)
  params: {
    hubStorageAccountResourceId: storageAccountResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    publicIPAddressDiagnosticSettingName: publicIPAddress.diagName
    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
    publicIPAddressName: publicIPAddress.name
  }
}]

module firewallDiagnosticSetting '../modules/firewall-diagnostic-setting.bicep' = {
  name: 'deploy-afw-diag-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hub.resourceGroupName)
  params: {
    firewallDiagnosticSettingsName: replace(hub.namingConvention.azureFirewallDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    firewallName: replace(hub.namingConvention.azureFirewall, '${delimiter}${tokens.purpose}', '')
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: firewallDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceIds[0]
    metrics: firewallDiagnosticsMetrics
  }
}

module keyVaultDiagnosticSettings '../modules/key-vault-diagnostic-setting.bicep' = [for (keyVault, i) in keyVaults: {
  name: 'deploy-kv-diag-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(keyVault.subscriptionId, keyVault.resourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: keyVault.diagnosticSettingName
    keyVaultName: keyVault.name
    keyVaultStorageAccountId: filter(storageAccountResourceIds, id => contains(id, keyVault.tierName))[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
    metrics: keyVaultDiagnosticMetrics
  }
}]

module bastionDiagnostics '../modules/bastion-diagnostic-setting.bicep' = if (deployBastion) {
  name: 'deploy-bastion-diag-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hub.resourceGroupName)
  params: {
    diagnosticSettingName: replace(hub.namingConvention.bastionHostDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: bastionDiagnosticsLogs
    metrics: bastionDiagnosticsMetrics
    name: replace(hub.namingConvention.bastionHost, '${delimiter}${tokens.purpose}', '')
    storageAccountResourceId: storageAccountResourceIds[0]
  }
}

module networkInterfaceDiagnostics '../modules/network-interface-diagnostic-setting.bicep' = [for (networkInterfaceResourceId, i) in networkInterfaceResourceIds: {
  name: 'deploy-nic-diag-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(networkInterfaceResourceId, '/')[2], split(networkInterfaceResourceId, '/')[4])
  params: {
    delimiter: delimiter
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: []
    metrics: networkInterfaceDiagnosticsMetrics
    networkInterfaceResourceId: networkInterfaceResourceId
    storageAccountResourceIds: storageAccountResourceIds
    tiers: tiers
    tokens: tokens
  }
}]
