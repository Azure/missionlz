/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param keyVaultDiagnosticSettingName string
param keyVaultName string
param keyVaultStorageAccountId string
param logAnalyticsWorkspaceResourceId string
param logs array
param metrics array

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: keyvault
  name: keyVaultDiagnosticSettingName
  properties: {
    logs: logs
    metrics: metrics
    storageAccountId: keyVaultStorageAccountId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}
