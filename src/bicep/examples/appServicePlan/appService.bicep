/*
Deployes a web server farm(aka: App Service Plan) to support web container deployments for Linux.  
Optionally enable dynamic auto scaling based on CPU Percentages using 'enableAutoScale' true/false
*/
targetScope = 'subscription'

@description('The name of the web server farm which will be created.  If unchanged or not specified, the MLZ resource prefix + "--ASP" will be utilized.')
param appServicePlanName string = 'placeHolder'

@description('The name of the resource group in which the app service plan will be deployed. If unchanged or not specified, the MLZ shared services resource group is used.')
param targetResourceGroup string = 'placeHolder'

@description('If true, enables dynamic scale-in & scale-out based on CPU percentages.  If false, then compute instances remain static with 2 instances supporting all traffic')
param enableAutoScale bool = true

var mlzDeploymentVariables = json(loadTextContent('../deploymentVariables.json'))
var appServicePlanName_Var = contains(appServicePlanName, 'placeHolder') ? '${mlzDeploymentVariables.mlzResourcePrefix.Value}--ASP' : appServicePlanName
var targetResourceGroup_Var = contains(targetResourceGroup, 'placeHolder') ? '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}' : targetResourceGroup
var targetSubscriptionId_Var = contains(targetResourceGroup, 'placeHolder') ? '${mlzDeploymentVariables.spokes.Value[2].subscriptionId}' : subscription().subscriptionId
var location = deployment().location
var kind = 'linux'
var capacity = 2
var sku = 'premium'

resource targetASPResourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: targetResourceGroup_Var
  location: location
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: appServicePlanName_Var
  scope: resourceGroup(targetSubscriptionId_Var, targetASPResourceGroup.name)
  params: {
    location: location
    svcPlanName: appServicePlanName_Var
    sku: sku
    capacity: capacity
    kind: kind
  }
}
module appServicePlanSettings 'modules/appServiceSettings.bicep' = if (enableAutoScale) {
  name: 'appServicePlanSettingsName'
  scope: resourceGroup(targetSubscriptionId_Var, targetASPResourceGroup.name)
  params: {
    location: location
    svcPlanName: appServicePlan.outputs.svcPlanName
    svcPlanNameID: appServicePlan.outputs.svcPlanID
  }
}
output appServicePlanName string = appServicePlanName_Var
output resourceGroupName string = targetResourceGroup_Var
