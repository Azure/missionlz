/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array
param networkSecurityGroupDiagnosticSettingName string
param networkSecurityGroupName string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: networkSecurityGroupName
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
