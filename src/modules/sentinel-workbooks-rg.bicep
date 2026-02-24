targetScope = 'resourceGroup'

@description('Name of the Log Analytics workspace where Microsoft Sentinel is enabled.')
param workspaceName string

@description('Azure region for the workbook resources.')
param location string

@description('Display name for the Azure Activity workbook.')
param azureActivityWorkbookName string

@description('Display name for the Azure Service Health workbook.')
param azureServiceHealthWorkbookName string

@description('Display name for the Microsoft Entra ID Audit logs workbook.')
param entraAuditWorkbookName string

@description('Display name for the Microsoft Entra ID Sign-in logs workbook.')
param entraSigninWorkbookName string

@description('Toggle to deploy the Azure Activity workbook.')
param deployAzureActivityWorkbook bool

@description('Toggle to deploy the Azure Service Health workbook.')
param deployServiceHealthWorkbook bool

@description('Toggle to deploy the Entra Audit workbook.')
param deployEntraAuditWorkbook bool

@description('Toggle to deploy the Entra Sign-in workbook.')
param deployEntraSigninWorkbook bool

@description('Azure Activity workbook JSON content.')
param azureActivityContent string

@description('Azure Service Health workbook JSON content.')
param serviceHealthContent string

@description('Entra Audit workbook JSON content.')
param entraAuditContent string

@description('Entra Sign-in workbook JSON content.')
param entraSigninContent string

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Generate deterministic GUIDs based on workspace ID and workbook name
// This ensures idempotent deployments - same input = same GUID
var azureActivityGuid = guid(workspace.id, azureActivityWorkbookName)
var serviceHealthGuid = guid(workspace.id, azureServiceHealthWorkbookName)
var entraAuditGuid = guid(workspace.id, entraAuditWorkbookName)
var entraSigninGuid = guid(workspace.id, entraSigninWorkbookName)

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
