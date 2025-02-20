/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deployNetworkWatcherTrafficAnalytics bool
param location string
param logAnalyticsWorkspaceResourceId string
param logStorageAccountResourceId string
param networkWatcherName string
param tiername string
param networkSecurityGroupResourceId string
param networkSecurityGroupFlowLogRetentionDays int

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
}

resource nsgFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  parent: networkWatcher
  name: '${tiername}-nsgflowLogs'
  location: location
  properties: {
    targetResourceId: networkSecurityGroupResourceId
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
      days: networkSecurityGroupFlowLogRetentionDays
      enabled: true
    }
  }
}
