/*
Deployes a premium Azure Container Registry suitable for hosting docker containers.
*/
targetScope = 'subscription'

param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))

@description('The name of the container registry which will be created. Must be globaly unique. No hyphens allowed, must be alpha numeric only, and between 5-50 characters.  If unchanged or not specified, the MLZ resource prefix + "acr" will be utilized.')
param contRegistryName string = replace('${mlzDeploymentVariables.mlzResourcePrefix.Value}${deployment().location}acr','-','')

@description('The name of the resource group in which the container registry will be deployed. If unchanged or not specified, the MLZ shared services resource group is used.')
param targetResourceGroup string = '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}'

var targetSubscriptionId_Var = targetResourceGroup == '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}' ? '${mlzDeploymentVariables.spokes.Value[2].subscriptionId}' : subscription().subscriptionId
var location = deployment().location

resource targetACRResourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: targetResourceGroup
  location: location
}

module containerRegistry 'modules/containerRegistry.bicep' = {
  scope: resourceGroup(targetSubscriptionId_Var, targetACRResourceGroup.name)
  name: contRegistryName
  params: {
    registryName: contRegistryName
  }
}

output azureContainerRegistryName string = contRegistryName
output azureContainerRegistryResourceGroup string = targetACRResourceGroup.name
