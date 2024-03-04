/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

param deploymentNameSuffix string
param keyVaultPrivateDnsZoneResourceId string
param location string
param networkProperties object
param subnetResourceId string
param tags object

module keyVault 'key-vault.bicep' = {
  name: 'deploy-key-vault-${deploymentNameSuffix}'
  scope: resourceGroup(networkProperties.subscriptionId, networkProperties.resourceGroupName)
  params: {
    keyVaultName: networkProperties.keyVaultName
    keyVaultNetworkInterfaceName: networkProperties.keyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: networkProperties.keyVaultPrivateEndpointName
    location: location
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

module diskEncryptionSet 'disk-encryption-set.bicep' = {
  name: 'deploy-disk-encryption-set_${deploymentNameSuffix}'
  scope: resourceGroup(networkProperties.subscriptionId, networkProperties.resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: networkProperties.diskEncryptionSetName
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    tags: contains(tags, 'Microsoft.Compute/diskEncryptionSets') ? tags['Microsoft.Compute/diskEncryptionSets'] : {}
  }
}

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-user-assigned-identity-${deploymentNameSuffix}'
  scope: resourceGroup(networkProperties.subscriptionId, networkProperties.resourceGroupName)
  params: {
    location: location
    name: networkProperties.userAssignedIdentityName
    tags: tags
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output keyVaultUri string = keyVault.outputs.keyVaultUri
output storageKeyName string = keyVault.outputs.storageKeyName
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
