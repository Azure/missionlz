/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param name string

param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: name
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: networkSecurityGroup
  name: '${networkSecurityGroup.name}-diagnostics'
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}
