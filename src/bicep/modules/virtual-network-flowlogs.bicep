/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param logAnalyticsWorkspaceResourceId string
param logStorageAccountResourceId string
param networkWatcherName string
param tiername string
param virtualNetworkResourceId string

var virtualNetworkFlowLogsName = '${networkWatcherName}//${tiername}-vnetflowLogs'


resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
}

//VNET Flow Logs


resource vnetFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = {
  name: virtualNetworkFlowLogsName
  location: location
  properties: {
    targetResourceId: virtualNetworkResourceId
    enabled: true
    storageId: logStorageAccountResourceId
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId:logAnalyticsWorkspaceResourceId
      }
    }
    format: {
      type: 'JSON'
      version: 2
    }
  }
}
