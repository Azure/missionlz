param diagnosticStorageAccountName string
param logAnalyticsWorkspaceName string
param enableDiagnostics bool = true

// Creating a symbolic name for an existing resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource stg 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: diagnosticStorageAccountName
}

resource security_notifications 'Microsoft.Security/securityContacts@2017-08-01-preview' existing = {
  name: 'securityNotifications'
  scope: subscription()
}


//// Setting log ananlytics to collect its own diagnostics to itself and to storage
resource logAnalyticsDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = if (enableDiagnostics) {
  name: 'enable-log-analytics-diagnostics'  
  scope: logAnalyticsWorkspace
  dependsOn: [
    stg
  ]
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
