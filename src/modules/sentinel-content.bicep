param azureActivityWorkbookName string = 'Azure Activity'
param azureServiceHealthWorkbookName string = 'Azure Service Health Workbook'
param deployAzureActivitySolution bool = true
param deployCustomWorkbooks bool = false
param deploymentNameSuffix string
param deployMicrosoftEntraSolution bool = true
param entraAuditWorkbookName string = 'Microsoft Entra ID Audit logs'
param entraSigninWorkbookName string = 'Microsoft Entra ID Sign-in logs'
param workspaceLocation string
param workspaceName string
param workspaceResourceGroupName string
param workspaceSubscriptionId string

var workspaceResourceId = resourceId(workspaceSubscriptionId, workspaceResourceGroupName, 'Microsoft.OperationalInsights/workspaces', workspaceName)

module azureActivitySolution '../data/sentinel/packages/azure-activity/mainTemplate.json' = if (deployAzureActivitySolution) {
  name: 'deploy-azure-activity-${deploymentNameSuffix}'
  params: {
    location: workspaceLocation
    'workspace-location': workspaceLocation
    workspace: workspaceName
    'workbook1-name': azureActivityWorkbookName
    'workbook2-name': azureServiceHealthWorkbookName
  }
}

module azureActivityWorkbook '../data/sentinel/custom-workbooks/deploy/AzureActivity.workbook.template.json' = if (deployAzureActivitySolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-azure-activity-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: azureActivityWorkbookName
  }
}

module azureServiceHealthWorkbook '../data/sentinel/custom-workbooks/deploy/AzureServiceHealthWorkbook.workbook.template.json' = if (deployAzureActivitySolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-azure-service-health-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: azureServiceHealthWorkbookName
  }
}

module microsoftEntraSolution '../data/sentinel/packages/microsoft-entra-id/mainTemplate.json' = if (deployMicrosoftEntraSolution) {
  name: 'deploy-entra-solution-${deploymentNameSuffix}'
  params: {
    location: workspaceLocation
    'workspace-location': workspaceLocation
    workspace: workspaceName
    'workbook1-name': entraAuditWorkbookName
    'workbook2-name': entraSigninWorkbookName
  }
}

module microsoftEntraAuditWorkbook '../data/sentinel/custom-workbooks/deploy/AzureActiveDirectoryAuditLogs.workbook.template.json' = if (deployMicrosoftEntraSolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-entra-audit-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: entraAuditWorkbookName
  }
}

module microsoftEntraSigninWorkbook '../data/sentinel/custom-workbooks/deploy/AzureActiveDirectorySignins.workbook.template.json' = if (deployMicrosoftEntraSolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-entra-signin-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: entraSigninWorkbookName
  }
}
