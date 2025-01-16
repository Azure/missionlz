/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
  scope: resourceGroup(networkWatcherResourceGroupName)
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

module virtualNetworkFlowLogs '../modules/virtual-network-flowlogs.bicep' = {
  name: 'deploy-${tiername}-flowLogs'
  scope: resourceGroup(networkWatcherResourceGroupName)
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorageAccountResourceId
    networkWatcherName: networkWatcher.name
    tiername: tiername
    virtualNetworkResourceId: virtualNetwork.id
  }
}
