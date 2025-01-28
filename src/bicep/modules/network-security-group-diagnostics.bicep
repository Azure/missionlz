/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
param deploymentNameSuffix string
param deployNsgFlowLogs bool
param location string
param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array
param networkSecurityGroupDiagnosticSettingName string
param networkSecurityGroupName string
param networkWatcherName string
param networkWatcherResourceGroupName string
param tiername string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: networkSecurityGroupName
}

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' existing = {
  name: networkWatcherName
  scope: resourceGroup(networkWatcherResourceGroupName)
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: networkSecurityGroup
  name: networkSecurityGroupDiagnosticSettingName
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

module nsgFlowLogs '../modules/network-security-group-flowlogs.bicep' = if (deployNsgFlowLogs) {
  name: 'deploy-${tiername}-flowLogs-${deploymentNameSuffix}'
  scope: resourceGroup(networkWatcherResourceGroupName)
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorageAccountResourceId
    networkWatcherName: networkWatcher.name
    tiername: tiername
    networkSecurityGroupResourceId: networkSecurityGroup.id
  }
}
