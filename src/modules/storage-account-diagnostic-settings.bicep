param blobDiagnosticSettingName string
param blobDiagnosticsLogs array
param blobDiagnosticsMetrics array
param fileDiagnosticSettingName string
param fileDiagnosticsLogs array
param fileDiagnosticsMetrics array
param logAnalyticsWorkspaceResourceId string
param logStorageAccountResourceId string
param queueDiagnosticSettingName string
param queueDiagnosticsLogs array
param queueDiagnosticsMetrics array
param storageAccountDiagnosticSettingName string
param storageAccountDiagnosticsLogs array
param storageAccountDiagnosticsMetrics array
param storageAccountName string
param tableDiagnosticSettingName string
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
  name: blobDiagnosticSettingName
  properties: {
    logs: blobDiagnosticsLogs
    metrics: blobDiagnosticsMetrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: blobService
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_fileService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: fileDiagnosticSettingName
  properties: {
    logs: fileDiagnosticsLogs
    metrics: fileDiagnosticsMetrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: fileService
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_queueService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: queueDiagnosticSettingName
  properties: {
    logs: queueDiagnosticsLogs
    metrics: queueDiagnosticsMetrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: queueService
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource diagnosticSetting_tableService 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: tableDiagnosticSettingName
  properties: {
    logs: tableDiagnosticsLogs
    metrics: tableDiagnosticsMetrics
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
  }
  scope: tableService
}
