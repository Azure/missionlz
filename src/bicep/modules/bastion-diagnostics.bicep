/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param bastionDiagnosticSettingName string
param bastionName string
param bastionStorageAccountId string
param logAnalyticsWorkspaceResourceId string
param logs array

resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01' existing = {
  name: bastionName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: bastionHost
  name: bastionDiagnosticSettingName
  properties: {
    storageAccountId: bastionStorageAccountId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
  }
}
