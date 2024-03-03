/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.

Deployes a premium Azure Key Vault to support hardware backed secrets and certificates storage
*/
targetScope = 'subscription'

@description('MLZ Deployment output variables in json format. It defaults to the deploymentVariables.json.')
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))
@description('Resource Id of the existing Log Analytics Workspace.')
param logAnalyticsWorkspaceResourceId string = mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value
@description('Resource Id of the existing Hub Subscription Id.')
param hubSubscriptionIdId string = mlzDeploymentVariables.hub.Value.subscriptionId
@description('Name of the existing Hub Resource Group.')
param hubResourceGroupName string = mlzDeploymentVariables.hub.Value.resourceGroupName

@description('The name of the key vault which will be created. Must be clobally unique, between 3 and 24 characters and only single hyphens permitted. If unchanged or not specified, the MLZ resource prefix + "-akv" will be utilized.')
param keyVaultName string = '${mlzDeploymentVariables.mlzResourcePrefix.Value}-akv'

@description('Deployment location')
param location string = deployment().location

@description('The name of the resource group in which the key vault will be deployed. If unchanged or not specified, the MLZ shared services resource group is used.')
param targetResourceGroup string = '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}'

@description('The resource id of the Virtual Network Subnet to attach the private endpoint to. If unchanged or not specified, the MLZ shared services VNET Subnet is used.')
param targetVirtualNetworkSubnetResourceId string = '${mlzDeploymentVariables.spokes.Value[2].subnetResourceId}'

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {}
var defaultTags = {
  DeploymentType: 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)

var targetSubscriptionId_Var = targetResourceGroup == '${mlzDeploymentVariables.spokes.Value[2].resourceGroupName}' ? '${mlzDeploymentVariables.spokes.Value[2].subscriptionId}' : subscription().subscriptionId
var keyVaultDnsName = replace(substring(keyVault.outputs.keyVaultUri, indexOf(keyVault.outputs.keyVaultUri, 'vault')), '/', '')
var keyVaultPrivateLinkZone = 'privatelink.${replace(keyVaultDnsName, 'vault', 'vaultcore')}'
var spokeVirtualNetworks = [for spoke in mlzDeploymentVariables.spokes.Value: {
  name: spoke.virtualNetworkName
  resourceId: spoke.virtualNetworkResourceId
}]  
var hubVirtualNetwork = [{
  name: mlzDeploymentVariables.hub.Value.virtualNetworkName
  resourceId: mlzDeploymentVariables.hub.Value.virtualNetworkResourceId
}]
var allVirtualNetworks = concat(hubVirtualNetwork,spokeVirtualNetworks)


module keyVault 'modules/key-vault.bicep' = {
  scope: resourceGroup(targetSubscriptionId_Var, targetResourceGroup)
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName
    location: location
    keyVaultSKU: 'premium'
    keyVaultTags: calculatedTags
    publicNetworkAccess: 'disabled'
    networkAclsDefaultAction: 'Deny'
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

module privateDnsZone 'modules/privateDnsZone.bicep' = {
  scope: resourceGroup(hubSubscriptionIdId, hubResourceGroupName)
  name: 'keyVaultPrivateDnsZone'
  params: {
    privateDnsZoneName: keyVaultPrivateLinkZone
    virtualNetworks: allVirtualNetworks
    tags: calculatedTags
  }
  dependsOn:[
    keyVault
  ]
}

module privateEndoint 'modules/privateEndpoint.bicep' = {
  scope: resourceGroup(targetSubscriptionId_Var, targetResourceGroup)
  name: 'keyVaultPrivateEndpoint'
  params: {
    location: location
    privateEndpointName: '${keyVaultName}-pve'
    privateEndpointTags: calculatedTags
    vnetSubnetResourceId: targetVirtualNetworkSubnetResourceId
    resourceId: keyVault.outputs.keyVaultResourceId
    privateEndpointResourceType: 'vault'
    privateDnsZoneResourceId: privateDnsZone.outputs.privateDnsZoneResourceId
  }
  dependsOn:[
    privateDnsZone
  ]
}

output azureKeyVaultName string = keyVaultName
output resourceGroupName string = targetResourceGroup
output tags object = calculatedTags
output keyVaultResourceId string = keyVault.outputs.keyVaultResourceId
output keyvaultUri string = keyVault.outputs.keyVaultUri
output keyVaultPrivateLinkZone string = keyVaultPrivateLinkZone
output keyVaultPrivateEndpointDnsConfigs array = privateEndoint.outputs.privateEndpointCustomDnsConfigs
