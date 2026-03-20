param azureActivityWorkbookName string
param azureServiceHealthWorkbookName string
param deployAzureActivityWorkbook bool = true
param deployEntraAuditWorkbook bool = true
param deployEntraSigninWorkbook bool = true
param deployServiceHealthWorkbook bool = true
param entraAuditWorkbookName string
param entraSigninWorkbookName string
param location string
param workspaceName string

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Generate deterministic GUIDs based on workspace ID and workbook name
// This ensures idempotent deployments - same input = same GUID
var azureActivityGuid = guid(workspace.id, azureActivityWorkbookName)
var serviceHealthGuid = guid(workspace.id, azureServiceHealthWorkbookName)
var entraAuditGuid = guid(workspace.id, entraAuditWorkbookName)
var entraSigninGuid = guid(workspace.id, entraSigninWorkbookName)

// Load workbook content from JSON files
var azureActivityContent = loadTextContent('../data/sentinel/workbooks/AzureActivity.json')
var serviceHealthContent = loadTextContent('../data/sentinel/workbooks/AzureServiceHealthWorkbook.json')
var entraAuditContent = loadTextContent('../data/sentinel/workbooks/AzureActiveDirectoryAuditLogs.json')
var entraSigninContent = loadTextContent('../data/sentinel/workbooks/AzureActiveDirectorySignins.json')

resource azureActivityWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = if (deployAzureActivityWorkbook) {
  name: azureActivityGuid
  location: location
  kind: 'shared'
  tags: {
    'hidden-title': azureActivityWorkbookName
  }
  properties: {
    displayName: azureActivityWorkbookName
    serializedData: azureActivityContent
    version: '1.0'
    sourceId: workspace.id
    category: 'sentinel'
  }
}

resource serviceHealthWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = if (deployServiceHealthWorkbook) {
  name: serviceHealthGuid
  location: location
  kind: 'shared'
  tags: {
    'hidden-title': azureServiceHealthWorkbookName
  }
  properties: {
    displayName: azureServiceHealthWorkbookName
    serializedData: serviceHealthContent
    version: '1.0'
    sourceId: workspace.id
    category: 'sentinel'
  }
}

resource entraAuditWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = if (deployEntraAuditWorkbook) {
  name: entraAuditGuid
  location: location
  kind: 'shared'
  tags: {
    'hidden-title': entraAuditWorkbookName
  }
  properties: {
    displayName: entraAuditWorkbookName
    serializedData: entraAuditContent
    version: '1.0'
    sourceId: workspace.id
    category: 'sentinel'
  }
}

resource entraSigninWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = if (deployEntraSigninWorkbook) {
  name: entraSigninGuid
  location: location
  kind: 'shared'
  tags: {
    'hidden-title': entraSigninWorkbookName
  }
  properties: {
    displayName: entraSigninWorkbookName
    serializedData: entraSigninContent
    version: '1.0'
    sourceId: workspace.id
    category: 'sentinel'
  }
}

output azureActivityWorkbookId string = deployAzureActivityWorkbook ? azureActivityWorkbook.id : ''
output serviceHealthWorkbookId string = deployServiceHealthWorkbook ? serviceHealthWorkbook.id : ''
output entraAuditWorkbookId string = deployEntraAuditWorkbook ? entraAuditWorkbook.id : ''
output entraSigninWorkbookId string = deployEntraSigninWorkbook ? entraSigninWorkbook.id : ''
