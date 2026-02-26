targetScope = 'subscription'

@description('Name of the Log Analytics workspace where Microsoft Sentinel is enabled.')
param workspaceName string

@description('Azure region for the workbook resources.')
param location string

@description('Resource group that contains the Microsoft Sentinel workspace.')
param workspaceResourceGroupName string

@description('Subscription identifier that contains the Microsoft Sentinel workspace.')
param workspaceSubscriptionId string

@description('Display name for the Azure Activity workbook.')
param azureActivityWorkbookName string = 'Azure Activity'

@description('Display name for the Azure Service Health workbook.')
param azureServiceHealthWorkbookName string = 'Azure Service Health Workbook'

@description('Display name for the Microsoft Entra ID Audit logs workbook.')
param entraAuditWorkbookName string = 'Microsoft Entra ID Audit logs'

@description('Display name for the Microsoft Entra ID Sign-in logs workbook.')
param entraSigninWorkbookName string = 'Microsoft Entra ID Sign-in logs'

@description('Toggle to deploy the Azure Activity workbook.')
param deployAzureActivityWorkbook bool = true

@description('Toggle to deploy the Azure Service Health workbook.')
param deployServiceHealthWorkbook bool = true

@description('Toggle to deploy the Entra Audit workbook.')
param deployEntraAuditWorkbook bool = true

@description('Toggle to deploy the Entra Sign-in workbook.')
param deployEntraSigninWorkbook bool = true

// Load workbook content from JSON files
var azureActivityContent = loadTextContent('../../sentinel/workbooks/AzureActivity.json')
var serviceHealthContent = loadTextContent('../../sentinel/workbooks/AzureServiceHealthWorkbook.json')
var entraAuditContent = loadTextContent('../../sentinel/workbooks/AzureActiveDirectoryAuditLogs.json')
var entraSigninContent = loadTextContent('../../sentinel/workbooks/AzureActiveDirectorySignins.json')

module workbooksDeployment 'sentinel-workbooks-rg.bicep' = {
  name: 'deploy-workbooks-resources'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    workspaceName: workspaceName
    location: location
    azureActivityWorkbookName: azureActivityWorkbookName
    azureServiceHealthWorkbookName: azureServiceHealthWorkbookName
    entraAuditWorkbookName: entraAuditWorkbookName
    entraSigninWorkbookName: entraSigninWorkbookName
    deployAzureActivityWorkbook: deployAzureActivityWorkbook
    deployServiceHealthWorkbook: deployServiceHealthWorkbook
    deployEntraAuditWorkbook: deployEntraAuditWorkbook
    deployEntraSigninWorkbook: deployEntraSigninWorkbook
    azureActivityContent: azureActivityContent
    serviceHealthContent: serviceHealthContent
    entraAuditContent: entraAuditContent
    entraSigninContent: entraSigninContent
  }
}

output azureActivityWorkbookId string = workbooksDeployment.outputs.azureActivityWorkbookId
output serviceHealthWorkbookId string = workbooksDeployment.outputs.serviceHealthWorkbookId
output entraAuditWorkbookId string = workbooksDeployment.outputs.entraAuditWorkbookId
output entraSigninWorkbookId string = workbooksDeployment.outputs.entraSigninWorkbookId
