/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param hubStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string
param name string
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' existing = {
  name: name
}

resource publicIpAddressDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: publicIPAddress
  name: '${publicIPAddress.name}-diagnostics'
  properties: {
    storageAccountId: hubStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: publicIPAddressDiagnosticsLogs
    metrics: publicIPAddressDiagnosticsMetrics
  }
}
