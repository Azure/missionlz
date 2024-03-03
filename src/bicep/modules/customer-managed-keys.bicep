/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

param deploymentNameSuffix string
param hubProperties object
param keyVaultPrivateDnsZoneResourceId string
param location string
param subnetResourceId string
param tags object

module keyVault 'key-vault.bicep' = {
  name: 'deploy-key-vault-${deploymentNameSuffix}'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    keyVaultName: hubProperties.keyVaultName
    keyVaultNetworkInterfaceName: hubProperties.keyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: hubProperties.keyVaultPrivateEndpointName
    location: location
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

module diskEncryptionSet 'disk-encryption-set.bicep' = {
  name: 'deploy-disk-encryption-set_${deploymentNameSuffix}'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetName: hubProperties.diskEncryptionSetName
    keyUrl: keyVault.outputs.keyUriWithVersion
    keyVaultResourceId: keyVault.outputs.keyVaultResourceId
    location: location
    tags: contains(tags, 'Microsoft.Compute/diskEncryptionSets') ? tags['Microsoft.Compute/diskEncryptionSets'] : {}
  }
}

module userAssignedIdentity 'user-assigned-identity.bicep' = {
  name: 'deploy-user-assigned-identity-${deploymentNameSuffix}'
  scope: resourceGroup(hubProperties.subscriptionId, hubProperties.resourceGroupName)
  params: {
    location: location
    name: hubProperties.userAssignedIdentityName
    tags: tags
  }
}

output diskEncryptionSetResourceId string = diskEncryptionSet.outputs.resourceId
output keyVaultUri string = keyVault.outputs.keyVaultUri
output storageKeyName string = keyVault.outputs.storageKeyName
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
