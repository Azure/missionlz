/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param firewallDiagnosticSettingsName string
param firewallName string
param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' existing = {
  name: firewallName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: firewall
  name: firewallDiagnosticSettingsName
  properties: {
    logs: logs
    metrics: metrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output privateIPAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
