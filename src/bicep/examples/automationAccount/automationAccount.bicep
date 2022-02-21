/*
Deployes an automation account with modules/runbook/diagnostic logs
Makes use of example azure automation bicep: https://github.com/Azure/bicep/tree/main/docs/examples/301/automation-account-import-runbooks-and-modules
*/
targetScope = 'subscription'

param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))

@description('The name of the automation account which will be created.  If unchanged or not specified, the MLZ resource prefix + "-aAc" will be utilized.')
param automationAcctName string = '${mlzDeploymentVariables.mlzResourcePrefix.Value}-aAc'

@description('The name of the resource group in which the automation account will be deployed. If unchanged or not specified, the MLZ operations resource group is used.')
param targetResourceGroup string = '${mlzDeploymentVariables.spokes.Value[1].resourceGroupName}'

@description('The URL location to the powershell runbook you wish to use')
param automationRunbook string

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}
var defaultTags = {
  'DeploymentType': 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)

var targetSubscriptionId_Var = targetResourceGroup == '${mlzDeploymentVariables.spokes.Value[1].resourceGroupName}' ? '${mlzDeploymentVariables.spokes.Value[1].subscriptionId}' : subscription().subscriptionId
var location = deployment().location

/* Log Analytics Variables */
var diagnosticStorageAccountName = '${}'

resource targetAAResourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: targetResourceGroup
  location: location
}

module automationAccount './modules/automationAccount.bicep' = {
  scope: resourceGroup(targetSubscriptionId_Var, targetAAResourceGroup.name)
  name: automationAcctName
  params: {
    name: automationAcctName
    location: location
    enableDiagnostics: true
    diagnosticStorageAccountName: ''
    diagnosticStorageAccountResourceGroup: ''
    logAnalyticsResourceGroup: ''
    logAnalyticsWorkspaceName: ''
    logAnalyticsSubscriptionId: ''
    modules: [
      {
        name: 'Az.Accounts'
        version: 'latest'
        uri: 'https://www.powershellgallery.com/api/v2/package'
      }
    ]
    runbooks: [
      {
        runbookName: 'MLZRunBook'
        runbookUri: automationRunbook
        runbookType: 'PowerShell'
        logProgress: true
        logVerbose: false
      }
    ]        
  }
}

output tags object = calculatedTags
