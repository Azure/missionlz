/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.

Deployes a web server farm(aka: App Service Plan) to support web container deployments for Linux.  
Optionally enable dynamic auto scaling based on CPU Percentages using 'enableAutoScale' true/false
*/
targetScope = 'subscription'

param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))

@description('The name of the web server farm which will be created.  If unchanged or not specified, the MLZ resource prefix + "--ASP" will be utilized.')
param appServicePlanName string = '${mlzDeploymentVariables.mlzResourcePrefix.Value}-asp'

@description('The name of the resource group in which the app service plan will be deployed. If unchanged or not specified, the MLZ shared services resource group is used.')
param targetResourceGroup string = '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}'

@description('If true, enables dynamic scale-in & scale-out based on CPU percentages.  If false, then compute instances remain static with 2 instances supporting all traffic')
param enableAutoScale bool = true

@description('Defines the performance tier of your web farm.  By default the performance scale will be premium 2nd generation version 2 "p2v2".  Another value would be standard generation 2 "s2".')
param appServiceSkuName string = 'p2v2'

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}
var defaultTags = {
  'DeploymentType': 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)

var targetSubscriptionId_Var = targetResourceGroup == '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}' ? '${mlzDeploymentVariables.spokes.Value[2].subscriptionId}' : subscription().subscriptionId
var location = deployment().location
var kind = 'linux'
var capacity = 2

resource targetASPResourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: targetResourceGroup
  location: location
  tags: calculatedTags
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: appServicePlanName
  scope: resourceGroup(targetSubscriptionId_Var, targetASPResourceGroup.name)
  params: {
    location: location
    svcPlanName: appServicePlanName
    sku: appServiceSkuName
    capacity: capacity
    kind: kind
    tags: calculatedTags
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

output appServicePlanName string = appServicePlanName
output resourceGroupName string = targetResourceGroup
output tags object = calculatedTags
