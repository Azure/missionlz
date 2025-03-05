/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
param deployNetworkWatcherTrafficAnalytics bool
param deployVirtualNetworkFlowLogs bool
param flowLogsName string
param location string
param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array
param networkWatcherName string
param networkWatcherResourceGroupName string
param tiername string
param virtualNetworkDiagnosticSettingName string
param virtualNetworkName string
param virtualNetworkFlowLogRetentionDays int

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: virtualNetwork
  name: virtualNetworkDiagnosticSettingName
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

module virtualNetworkFlowLogs '../modules/virtual-network-flowlogs.bicep' = if (deployVirtualNetworkFlowLogs) {
  name: 'deploy-${tiername}-flowLogs-${deploymentNameSuffix}'
  scope: resourceGroup(networkWatcherResourceGroupName)
  params: {
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: flowLogsName
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorageAccountResourceId
    networkWatcherName: networkWatcherName
    virtualNetworkResourceId: virtualNetwork.id
    virtualNetworkFlowLogRetentionDays: virtualNetworkFlowLogRetentionDays
  }
}
