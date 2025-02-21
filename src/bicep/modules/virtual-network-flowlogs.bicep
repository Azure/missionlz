/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deployNetworkWatcherTrafficAnalytics bool
param flowLogsName string
param location string
param logAnalyticsWorkspaceResourceId string
param logStorageAccountResourceId string
param networkWatcherName string
param virtualNetworkFlowLogRetentionDays int
param virtualNetworkResourceId string

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
}

resource vnetFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  parent: networkWatcher
  name: flowLogsName
  location: location
  properties: {
    targetResourceId: virtualNetworkResourceId
    enabled: true
    storageId: logStorageAccountResourceId
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: deployNetworkWatcherTrafficAnalytics ? deployNetworkWatcherTrafficAnalytics : null
        workspaceResourceId: deployNetworkWatcherTrafficAnalytics ? logAnalyticsWorkspaceResourceId : null
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      days: virtualNetworkFlowLogRetentionDays
      enabled: true
    }
  }
}
