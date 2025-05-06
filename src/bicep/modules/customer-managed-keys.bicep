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
param resourceAbbreviations object
param resourceGroupName string
param subnetResourceId string
param tags object
param tier object
param workloadShortName string

module keyVault 'key-vault.bicep' = {
  name: 'deploy-kv-${workloadShortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    environmentAbbreviation: environmentAbbreviation
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: mlzTags
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: subnetResourceId
    tags: tags
    tier: tier
  }
}

module diskEncryptionSet 'disk-encryption-set.bicep' = {
  name: 'deploy-des-${workloadShortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: tier.namingConvention.diskEncryptionSet
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    mlzTags: mlzTags
    tags: tags
    workloadShortName: workloadShortName
  }
}

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-id-${workloadShortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    mlzTags: mlzTags
    tags: tags
    userAssignedIdentityName: tier.namingConvention.userAssignedIdentity
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output keyVaultResourceId string = keyVault.outputs.keyVaultResourceId
output networkInterfaceResourceIds array = [
  keyVault.outputs.networkInterfaceResourceId
]
output storageKeyName string = keyVault.outputs.storageKeyName
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
