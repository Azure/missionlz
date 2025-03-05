/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
param deployNetworkSecurityGroupFlowLogs bool
param deployNetworkWatcherTrafficAnalytics bool
param flowLogsName string
param location string
param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array
param networkSecurityGroupDiagnosticSettingName string
param networkSecurityGroupName string
param networkWatcherName string
param networkWatcherResourceGroupName string
param networkSecurityGroupFlowLogRetentionDays int
param tiername string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: networkSecurityGroupName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: networkSecurityGroup
  name: networkSecurityGroupDiagnosticSettingName
  properties: {
    logs: logs
    metrics: metrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

module nsgFlowLogs '../modules/network-security-group-flowlogs.bicep' = if (deployNetworkSecurityGroupFlowLogs) {
  name: 'deploy-${tiername}-flowLogs-${deploymentNameSuffix}'
  scope: resourceGroup(networkWatcherResourceGroupName)
  params: {
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    flowLogsName: flowLogsName
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorageAccountResourceId
    networkSecurityGroupFlowLogRetentionDays: networkSecurityGroupFlowLogRetentionDays
    networkSecurityGroupResourceId: networkSecurityGroup.id
    networkWatcherName: networkWatcherName
  }
}
