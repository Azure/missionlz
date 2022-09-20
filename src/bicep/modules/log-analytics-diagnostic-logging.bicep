/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param diagnosticStorageAccountName string
param logAnalyticsWorkspaceName string

param supportedClouds array = [
  'AzureCloud'
  'AzureUSGovernment'
]

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource stg 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: diagnosticStorageAccountName
}

//// Setting log analytics to collect its own diagnostics to itself and to storage
resource logAnalyticsDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = if (contains(supportedClouds, environment().name)) {
  name: 'enable-log-analytics-diagnostics'
  scope: logAnalyticsWorkspace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    storageAccountId: stg.id
    logs: [
      {
        category: 'Audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
