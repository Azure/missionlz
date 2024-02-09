/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param diskEncryptionSetName string
param deploymentNameSuffix string
param keyVaultName string
param keyVaultNetworkInterfaceName string
param keyVaultPrivateDnsZoneResourceId string
param keyVaultPrivateEndpointName string
param location string
param subnetResourceId string
param tags object
param userAssignedIdentityName string

module keyVault '../modules/key-vault.bicep' = {
  name: 'deploy-key-vault-${deploymentNameSuffix}'
  params: {
    keyVaultName: keyVaultName
    keyVaultNetworkInterfaceName: keyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    location: location
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

module diskEncryptionSet '../modules/disk-encryption-set.bicep' = {
  name: 'deploy-disk-encryption-set_${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: diskEncryptionSetName
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    tags: contains(tags, 'Microsoft.Compute/diskEncryptionSets') ? tags['Microsoft.Compute/diskEncryptionSets'] : {}
  }
}

module userAssignedIdentity '../modules/user-assigned-identity.bicep' = {
  name: 'deploy-user-assigned-identity-${deploymentNameSuffix}'
  params: {
    location: location
    name: userAssignedIdentityName
    tags: tags
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output keyVaultUri string = keyVault.outputs.keyVaultUri
output storageKeyName string = keyVault.outputs.storageKeyName
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
