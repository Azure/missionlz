/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param environmentAbbreviation string
param keyVaultPrivateDnsZoneResourceId string
param location string
param mlzTags object
param resourceGroupName string
param subnetResourceId string
param tags object
param tier object

module keyVault 'key-vault.bicep' = {
  name: 'deploy-cmk-kv-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    environmentAbbreviation: environmentAbbreviation
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: mlzTags
    resourceAbbreviations: tier.resourceAbbreviations
    subnetResourceId: subnetResourceId
    tags: tags
    tier: tier
  }
}

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-cmk-id-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    mlzTags: mlzTags
    tags: tags
    userAssignedIdentityName: tier.namingConvention.userAssignedIdentity
  }
}

output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output keyVaultResourceId string = keyVault.outputs.keyVaultResourceId
output networkInterfaceResourceIds array = [
  keyVault.outputs.networkInterfaceResourceId
]
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
