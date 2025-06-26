/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param hubStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string
param publicIPAddressDiagnosticSettingName string
param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array
param publicIPAddressName string

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' existing = {
  name: publicIPAddressName
}

resource publicIpAddressDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: publicIPAddress
  name: publicIPAddressDiagnosticSettingName
  properties: {
    storageAccountId: hubStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: publicIPAddressDiagnosticsLogs
    metrics: publicIPAddressDiagnosticsMetrics
  }
}
