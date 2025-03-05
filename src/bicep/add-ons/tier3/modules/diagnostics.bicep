/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deployActivityLogDiagnosticSetting bool
param deployNetworkSecurityGroupFlowLogs bool
param deployNetworkWatcherTrafficAnalytics bool
param deploymentNameSuffix string
param deployVirtualNetworkFlowLogs bool
param keyVaultDiagnosticLogs array
param keyVaultName string
param location string
param logAnalyticsWorkspaceResourceId string
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array
param networkSecurityGroupFlowLogRetentionDays int
param networkSecurityGroupName string
param networkWatcherResourceId string
param resourceGroupName string
param serviceToken string
param storageAccountResourceId string
param tier object
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array
param virtualNetworkFlowLogRetentionDays int
param virtualNetworkName string

module activityLogDiagnosticSettings '../../../modules/activity-log-diagnostic-settings.bicep' =
  if (deployActivityLogDiagnosticSetting) {
    name: 'deploy-activity-diags-${tier.shortName}-${deploymentNameSuffix}'
    scope: subscription(tier.subscriptionId)
    params: {
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    }
  }

module keyvaultDiagnostics '../../../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: replace(tier.namingConvention.keyVaultDiagnosticSetting, '${serviceToken}-', '')
    keyVaultName: keyVaultName
    keyVaultStorageAccountId: storageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
  }
}  

module networkSecurityGroupDiagnostics '../../../modules/network-security-group-diagnostics.bicep' = {
  name: 'deploy-nsg-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkSecurityGroupFlowLogs: deployNetworkSecurityGroupFlowLogs
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tier.namingConvention.networkWatcherFlowLogsNetworkSecurityGroup
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: networkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupDiagnosticSettingName: tier.namingConvention.networkSecurityGroupDiagnosticSetting
    networkSecurityGroupFlowLogRetentionDays: networkSecurityGroupFlowLogRetentionDays
    networkSecurityGroupName: networkSecurityGroupName
    networkWatcherName: tier.namingConvention.networkWatcherName
    networkWatcherResourceGroupName: empty(networkWatcherResourceId) ? resourceGroupName : split(networkWatcherResourceId, '/')[4]
    tiername: tier.name
  }
}

module virtualNetworkDiagnostics '../../../modules/virtual-network-diagnostics.bicep' = {
  name: 'deploy-vnet-diags-${tier.shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    deployVirtualNetworkFlowLogs: deployVirtualNetworkFlowLogs
    flowLogsName: tier.namingConvention.networkWatcherFlowLogsVirtualNetwork
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: virtualNetworkDiagnosticsMetrics
    networkWatcherName: empty(networkWatcherResourceId) ? tier.namingConvention.networkWatcher : split(networkWatcherResourceId, '/')[8]
    networkWatcherResourceGroupName: empty(networkWatcherResourceId) ? resourceGroupName : split(networkWatcherResourceId, '/')[4]
    tiername: tier.name
    virtualNetworkDiagnosticSettingName: tier.namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkFlowLogRetentionDays: virtualNetworkFlowLogRetentionDays
    virtualNetworkName: virtualNetworkName
  }
}
