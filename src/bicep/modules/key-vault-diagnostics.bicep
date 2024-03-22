/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param logAnalyticsWorkspaceResourceId string
param logs array
param name string

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: name
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: keyvault
  name: '${keyvault.name}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
  }
}
