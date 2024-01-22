/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param logAnalyticsWorkspaceResourceId string
param logs array
param logStorageAccountResourceId string
param metrics array
param name string

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' existing = {
  name: name
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: firewall
  name: '${firewall.name}-diagnostics'
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

output privateIPAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
