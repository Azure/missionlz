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

var nsgFlowLogsName = '${networkWatcherName}//${tiername}-nsgflowLogs'


resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
}

//VNET Flow Logs


resource nsgFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  name: nsgFlowLogsName
  location: location
  properties: {
    targetResourceId: networkSecurityGroupResourceId
    enabled: true
    storageId: logStorageAccountResourceId
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: deployNetworkWatcherTrafficAnalytics ? deployNetworkWatcherTrafficAnalytics : json('null')
        workspaceResourceId: deployNetworkWatcherTrafficAnalytics ? logAnalyticsWorkspaceResourceId : json('null')
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
