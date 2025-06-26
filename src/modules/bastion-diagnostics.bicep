/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param diagnosticSettingName string
param logAnalyticsWorkspaceResourceId string
param logs array
param metrics array
param name string
param storageAccountResourceId string

resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01' existing = {
  name: name
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: bastionHost
  name: diagnosticSettingName
  properties: {
    logs: logs
    metrics: metrics
    storageAccountId: storageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
