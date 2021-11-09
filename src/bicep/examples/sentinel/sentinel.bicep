/*
//
//Makes use of a global variable json file to provide necessary information to support the deployment of Azure Sentinel 
//
//To create the 'deploymentVariables.json' file from your MLZ deployment in PowerShell:
//
//--  (Get-AzSubscriptionDeployment -Name <MLZDeploymentName>).outputs | ConvertTo-Json -Depth 10 | Out-File -FilePath .\deploymentVariables.json
//
//Retrieve the MLZ deployment name by browsing to 'Subscriptions', to the subscription you deployed into, and then look at 'Deployments'
//
//Requires PowerShell Core (avaliable for all operating systems):  https://github.com/PowerShell/PowerShell/releases
//Requires Azure PowerShell Module (avaliable for all operating systems): https://docs.microsoft.com/en-us/powershell/azure/install-az-ps
//
//By-pass the use of the deploymentVariables.json file altogther by calling the './modules/deploySentinel.bicep' file directly with the required informaiton.
//
*/
targetScope = 'subscription'

var mlzDeploymentVariables = json(loadTextContent('../deploymentVariables.json'))
var sentinelSolutionName = 'SecurityInsights(${mlzDeploymentVariables.logAnalyticsWorkspaceName.Value})'
var logAnalyticsWorkspaceResourceId = '${mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value}'
var operationsResourceGroupName = '${mlzDeploymentVariables.spokes.Value[0].resourceGroupName}'
var operationsSubscriptionId = '${mlzDeploymentVariables.spokes.Value[0].subscriptionId}'
module deploySentinel 'modules/deploySentinel.bicep' = {
  name: 'deploySentinel'
  params: {
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    sentinelSolutionName: sentinelSolutionName
  }
  scope: resourceGroup(operationsSubscriptionId,operationsResourceGroupName)
}
