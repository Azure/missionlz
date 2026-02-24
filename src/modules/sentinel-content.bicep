targetScope = 'subscription'

@description('Suffix appended to the deployment name so module executions remain unique per run.')
param deploymentNameSuffix string

@description('Name of the Log Analytics workspace where Microsoft Sentinel is enabled.')
param workspaceName string

@description('Azure region that hosts the Log Analytics workspace.')
param workspaceLocation string

@description('Resource group that contains the Microsoft Sentinel workspace.')
param workspaceResourceGroupName string

@description('Subscription identifier that contains the Microsoft Sentinel workspace.')
param workspaceSubscriptionId string

@description('Display name assigned to the Azure Activity workbook that ships with the solution package.')
param azureActivityWorkbookName string = 'Azure Activity'

@description('Display name assigned to the Azure Service Health workbook included in the Azure Activity solution package.')
param azureServiceHealthWorkbookName string = 'Azure Service Health Workbook'

@description('Display name assigned to the Microsoft Entra ID audit workbook that ships with the solution package.')
param entraAuditWorkbookName string = 'Microsoft Entra ID Audit logs'

@description('Display name assigned to the Microsoft Entra ID sign-in workbook that ships with the solution package.')
param entraSigninWorkbookName string = 'Microsoft Entra ID Sign-in logs'

@description('Toggle to install the Azure Activity Microsoft Sentinel solution when Microsoft Sentinel is enabled.')
param deployAzureActivitySolution bool = true

@description('Toggle to install the Microsoft Entra ID Microsoft Sentinel solution when Microsoft Sentinel is enabled.')
param deployMicrosoftEntraSolution bool = true

@description('Deploy custom workbooks in addition to Content Hub solutions. Set to false to avoid duplicate workbooks.')
param deployCustomWorkbooks bool = false

var workspaceResourceId = resourceId(workspaceSubscriptionId, workspaceResourceGroupName, 'Microsoft.OperationalInsights/workspaces', workspaceName)

module azureActivitySolution '../../sentinel/packages/azure-activity/mainTemplate.json' = if (deployAzureActivitySolution) {
  name: 'deploy-azure-activity-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    location: workspaceLocation
    'workspace-location': workspaceLocation
    workspace: workspaceName
    'workbook1-name': azureActivityWorkbookName
    'workbook2-name': azureServiceHealthWorkbookName
  }
}

module azureActivityWorkbook '../../sentinel/custom-workbooks/deploy/AzureActivity.workbook.template.json' = if (deployAzureActivitySolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-azure-activity-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: azureActivityWorkbookName
  }
}

module azureServiceHealthWorkbook '../../sentinel/custom-workbooks/deploy/AzureServiceHealthWorkbook.workbook.template.json' = if (deployAzureActivitySolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-azure-service-health-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: azureServiceHealthWorkbookName
  }
}

module microsoftEntraSolution '../../sentinel/packages/microsoft-entra-id/mainTemplate.json' = if (deployMicrosoftEntraSolution) {
  name: 'deploy-entra-solution-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    location: workspaceLocation
    'workspace-location': workspaceLocation
    workspace: workspaceName
    'workbook1-name': entraAuditWorkbookName
    'workbook2-name': entraSigninWorkbookName
  }
}

module microsoftEntraAuditWorkbook '../../sentinel/custom-workbooks/deploy/AzureActiveDirectoryAuditLogs.workbook.template.json' = if (deployMicrosoftEntraSolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-entra-audit-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: entraAuditWorkbookName
  }
}

module microsoftEntraSigninWorkbook '../../sentinel/custom-workbooks/deploy/AzureActiveDirectorySignins.workbook.template.json' = if (deployMicrosoftEntraSolution && deployCustomWorkbooks) {
  name: 'deploy-workbook-entra-signin-${deploymentNameSuffix}'
  scope: resourceGroup(workspaceSubscriptionId, workspaceResourceGroupName)
  params: {
    workspaceResourceId: workspaceResourceId
    location: workspaceLocation
    displayName: entraSigninWorkbookName
  }
}
