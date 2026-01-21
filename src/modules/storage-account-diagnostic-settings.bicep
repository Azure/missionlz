param blobDiagnosticsLogs array
param blobDiagnosticsMetrics array
param fileDiagnosticsLogs array
param fileDiagnosticsMetrics array
param logAnalyticsWorkspaceResourceId string
param logStorageAccountResourceId string
param queueDiagnosticsLogs array
param queueDiagnosticsMetrics array
param storageAccountDiagnosticSettingName string
param storageAccountDiagnosticsLogs array
param storageAccountDiagnosticsMetrics array
param storageAccountName string
param tableDiagnosticsLogs array
param tableDiagnosticsMetrics array

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource diagnosticSetting_storageAccount 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: storageAccountDiagnosticSettingName
  properties: {
    logs: storageAccountDiagnosticsLogs
    metrics: storageAccountDiagnosticsMetrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: storageAccount
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_blobService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: storageAccountDiagnosticSettingName
  properties: {
    logs: blobDiagnosticsLogs
    metrics: blobDiagnosticsMetrics
    storageAccountId: storageAccount.id
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: blobService
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_fileService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: storageAccountDiagnosticSettingName
  properties: {
    logs: fileDiagnosticsLogs
    metrics: fileDiagnosticsMetrics
    storageAccountId: storageAccount.id
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: fileService
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_queueService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: storageAccountDiagnosticSettingName
  properties: {
    logs: queueDiagnosticsLogs
    metrics: queueDiagnosticsMetrics
    storageAccountId: storageAccount.id
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: queueService
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_tableService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: storageAccountDiagnosticSettingName
  properties: {
    logs: tableDiagnosticsLogs
    metrics: tableDiagnosticsMetrics
    storageAccountId: storageAccount.id
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: tableService
}
