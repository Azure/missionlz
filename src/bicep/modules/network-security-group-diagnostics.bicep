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
param networkSecurityGroupDiagnosticSettingName string
param networkSecurityGroupName string
param networkWatcherFlowLogsRetentionDays int
param networkWatcherFlowLogsType string
param networkWatcherName string
param networkWatcherResourceGroupName string
param networkWatcherSubscriptionId string
param storageAccountResourceId string
param tiername string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: networkSecurityGroupName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: networkSecurityGroup
  name: networkSecurityGroupDiagnosticSettingName
  properties: {
    logs: logs
    metrics: []
    storageAccountId: storageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

module nsgFlowLogs '../modules/network-watcher-flow-logs.bicep' = if (networkWatcherFlowLogsType == 'NetworkSecurityGroup') {
  name: 'deploy-${tiername}-flowLogs-${deploymentNameSuffix}'
  scope: resourceGroup(networkWatcherSubscriptionId, networkWatcherResourceGroupName)
  params: {
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: flowLogsName
    flowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    networkWatcherName: networkWatcherName
    storageAccountResourceId: storageAccountResourceId
    targetResourceId: networkSecurityGroup.id
  }
}
