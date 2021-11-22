/*
Deployes a premium Azure Key Vault to support hardware backed secrets and certificates storage
*/
targetScope = 'subscription'

param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))

@description('The name of the key vault which will be created. Must be clobally unique, between 3 and 24 characters and only single hyphens permitted. If unchanged or not specified, the MLZ resource prefix + "-akv" will be utilized.')
param keyVaultName string = '${mlzDeploymentVariables.mlzResourcePrefix.Value}-akv'

@description('The name of the resource group in which the key vault will be deployed. If unchanged or not specified, the MLZ shared services resource group is used.')
param targetResourceGroup string = '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}'

var targetSubscriptionId_Var = targetResourceGroup == '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}' ? '${mlzDeploymentVariables.spokes.Value[2].subscriptionId}' : subscription().subscriptionId
var location = deployment().location


resource targetASPResourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  name: targetResourceGroup
  location: location
}

module deployAzureKeyVault 'modules/keyVault.bicep' = {
  scope: resourceGroup(targetSubscriptionId_Var, targetASPResourceGroup.name)
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName
    tenantID: subscription().tenantId
  }
}

output azureKeyVaultName string = keyVaultName
output resourceGroupName string = targetResourceGroup
