/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
param deployNetworkWatcherTrafficAnalytics bool
param flowLogsName string
param location string
param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array
param networkWatcherFlowLogsRetentionDays int
param networkWatcherFlowLogsType string
param supportedClouds array = [
  'AzureCloud'
]
param tiername string
param virtualNetworkDiagnosticSettingName string
param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: virtualNetwork
  name: virtualNetworkDiagnosticSettingName
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: contains(supportedClouds, environment().name) ?  logs : []
    metrics: metrics
  }
}

module virtualNetworkFlowLogs '../modules/network-watcher-flow-logs.bicep' = if (networkWatcherFlowLogsType == 'VirtualNetwork') {
  name: 'deploy-${tiername}-flowLogs-${deploymentNameSuffix}'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: flowLogsName
    flowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    networkWatcherName: 'NetworkWatcher_${location}'
    storageAccountResourceId: logStorageAccountResourceId
    targetResourceId: virtualNetwork.id
  }
}
