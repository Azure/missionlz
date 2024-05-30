/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param keyVaultPrivateDnsZoneResourceId string
param location string
param mlzTags object
param resourceGroupName string
param subnetResourceId string
param tags object
param tier object
param tokens object
param workloadShortName string

module keyVault 'key-vault.bicep' = {
  name: 'deploy-kv-${workloadShortName}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    keyVaultName: take(replace(tier.namingConvention.keyVault, tokens.service, ''), 24)
    keyVaultNetworkInterfaceName: replace(tier.namingConvention.keyVaultNetworkInterface, tokens.service, '')
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: replace(tier.namingConvention.keyVaultPrivateEndpoint, tokens.service, '')
    location: location
    mlzTags: mlzTags
    subnetResourceId: subnetResourceId
    tags: tags
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
    tags: contains(tags, 'Microsoft.Compute/diskEncryptionSets') ? tags['Microsoft.Compute/diskEncryptionSets'] : {}
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
    userAssignedIdentityName: replace(tier.namingConvention.userAssignedIdentity, '-${tokens.service}', '')
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output keyVaultResourceId string = keyVault.outputs.keyVaultResourceId
output storageKeyName string = keyVault.outputs.storageKeyName
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
