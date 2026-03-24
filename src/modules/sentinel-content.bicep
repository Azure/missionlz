param azureActivityWorkbookName string = 'Azure Activity'
param azureServiceHealthWorkbookName string = 'Azure Service Health Workbook'
param deployAzureActivitySolution bool = true
param deployCustomWorkbooks bool = false
param deploymentNameSuffix string
param deployMicrosoftEntraSolution bool = true
param entraAuditWorkbookName string = 'Microsoft Entra ID Audit logs'
param entraSigninWorkbookName string = 'Microsoft Entra ID Sign-in logs'
param location string
param logAnalyticsWorkspaceResourceId string

module azureActivitySolution '../data/sentinel/packages/azure-activity/solution.bicep' = if (deployAzureActivitySolution) {
  name: 'deploy-azure-activity-${deploymentNameSuffix}'
  params: {
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    workbook1Name: azureActivityWorkbookName
    workbook2Name: azureServiceHealthWorkbookName
  }
}

module azureActivityWorkbook '../data/sentinel/custom-workbooks/deploy/AzureActivity.workbook.template.json' = if (deployAzureActivitySolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-azure-activity-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
    displayName: azureActivityWorkbookName
  }
}

module azureServiceHealthWorkbook '../data/sentinel/custom-workbooks/deploy/AzureServiceHealthWorkbook.workbook.template.json' = if (deployAzureActivitySolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-azure-service-health-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
    displayName: azureServiceHealthWorkbookName
  }
}

module microsoftEntraSolution '../data/sentinel/packages/microsoft-entra-id/mainTemplate.json' = if (deployMicrosoftEntraSolution) {
  name: 'deploy-entra-solution-${deploymentNameSuffix}'
  params: {
    location: location
    'workspace-location': location
    workspace: split(logAnalyticsWorkspaceResourceId, '/')[8]
    'workbook1-name': entraAuditWorkbookName
    'workbook2-name': entraSigninWorkbookName
  }
}

module microsoftEntraAuditWorkbook '../data/sentinel/custom-workbooks/deploy/AzureActiveDirectoryAuditLogs.workbook.template.json' = if (deployMicrosoftEntraSolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-entra-audit-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
    displayName: entraAuditWorkbookName
  }
}

module microsoftEntraSigninWorkbook '../data/sentinel/custom-workbooks/deploy/AzureActiveDirectorySignins.workbook.template.json' = if (deployMicrosoftEntraSolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-entra-signin-${deploymentNameSuffix}'
  params: {
    workspaceResourceId: logAnalyticsWorkspaceResourceId
    location: location
    displayName: entraSigninWorkbookName
  }
}
