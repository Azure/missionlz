/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deployActivityLogDiagnosticSetting bool
param deploymentNameSuffix string
param deployNetworkWatcherTrafficAnalytics bool
param keyVaultDiagnosticLogs array
param keyVaultDiagnosticMetrics array
param keyVaultName string
param location string
param logAnalyticsWorkspaceResourceId string
param networkInterfaceDiagnosticsMetrics array
param networkInterfaceResourceIds array
param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupName string
param networkWatcherFlowLogsRetentionDays int
param networkWatcherFlowLogsType string
param networkWatcherResourceId string
param resourceGroupName string
param serviceToken string
param storageAccountResourceId string
param tiers array
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array
param virtualNetworkName string

module activityLogDiagnosticSettings '../../../modules/activity-log-diagnostic-settings.bicep' =
  if (deployActivityLogDiagnosticSetting) {
    name: 'deploy-activity-diags-${tiers[0].shortName}-${deploymentNameSuffix}'
    scope: subscription(tiers[0].subscriptionId)
    params: {
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    }
  }

module keyvaultDiagnostics '../../../modules/key-vault-diagnostics.bicep' = {
  name: 'deploy-kv-diags-${tiers[0].shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tiers[0].subscriptionId, resourceGroupName)
  params: {
    keyVaultDiagnosticSettingName: replace(tiers[0].namingConvention.keyVaultDiagnosticSetting, '${serviceToken}-', '')
    keyVaultName: keyVaultName
    keyVaultStorageAccountId: storageAccountResourceId
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: keyVaultDiagnosticLogs
    metrics: keyVaultDiagnosticMetrics
  }
}  

module networkSecurityGroupDiagnostics '../../../modules/network-security-group-diagnostics.bicep' = {
  name: 'deploy-nsg-diags-${tiers[0].shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tiers[0].subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tiers[0].namingConvention.networkWatcherFlowLogsNetworkSecurityGroup
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticSettingName: tiers[0].namingConvention.networkSecurityGroupDiagnosticSetting
    networkSecurityGroupName: networkSecurityGroupName
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherName: empty(networkWatcherResourceId) ? tiers[0].namingConvention.networkWatcher : split(networkWatcherResourceId, '/')[8]
    networkWatcherResourceGroupName: empty(networkWatcherResourceId) ? resourceGroupName : split(networkWatcherResourceId, '/')[4]
    networkWatcherSubscriptionId: empty(networkWatcherResourceId) ? tiers[0].subscriptionId : split(networkWatcherResourceId, '/')[2]
    storageAccountResourceId: storageAccountResourceId
    tiername: tiers[0].name
  }
}

module virtualNetworkDiagnostics '../../../modules/virtual-network-diagnostics.bicep' = {
  name: 'deploy-vnet-diags-${tiers[0].shortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tiers[0].subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: tiers[0].namingConvention.networkWatcherFlowLogsVirtualNetwork
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: virtualNetworkDiagnosticsLogs
    logStorageAccountResourceId: storageAccountResourceId
    metrics: virtualNetworkDiagnosticsMetrics
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherName: empty(networkWatcherResourceId) ? tiers[0].namingConvention.networkWatcher : split(networkWatcherResourceId, '/')[8]
    networkWatcherResourceGroupName: empty(networkWatcherResourceId) ? resourceGroupName : split(networkWatcherResourceId, '/')[4]
    networkWatcherSubscriptionId: empty(networkWatcherResourceId) ? tiers[0].subscriptionId : split(networkWatcherResourceId, '/')[2]
    tiername: tiers[0].name
    virtualNetworkDiagnosticSettingName: tiers[0].namingConvention.virtualNetworkDiagnosticSetting
    virtualNetworkName: virtualNetworkName
  }
}

module networkInterfaceDiagnostics '../../../modules/network-interface-diagnostics.bicep' = [for (networkInterfaceResourceId, i) in networkInterfaceResourceIds: {
  name: 'deploy-nic-diags-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(networkInterfaceResourceId, '/')[2], split(networkInterfaceResourceId, '/')[4])
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logs: []
    metrics: networkInterfaceDiagnosticsMetrics
    networkInterfaceResourceId: networkInterfaceResourceId
    storageAccountResourceIds: [
      storageAccountResourceId
    ]
    tiers: tiers
  }
}]
