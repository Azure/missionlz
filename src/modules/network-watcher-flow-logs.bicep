/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deployNetworkWatcherTrafficAnalytics bool
param flowLogsName string
param flowLogsRetentionDays int
param location string
param logAnalyticsWorkspaceResourceId string
param networkWatcherName string
param storageAccountResourceId string
param targetResourceId string

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
}

resource nsgFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  parent: networkWatcher
  name: flowLogsName
  location: location
  properties: {
    targetResourceId: targetResourceId
    enabled: true
    storageId: storageAccountResourceId
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
      days: flowLogsRetentionDays
      enabled: true
    }
  }
}
