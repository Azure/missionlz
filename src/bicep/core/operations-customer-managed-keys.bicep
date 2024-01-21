/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param keyVaultName string
param keyVaultPrivateDnsZoneResourceId string
param location string
param resourcePrefix string
param subnetResourceId string
param tags object
param userAssignedIdentityName string

module keyVault '../modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: keyVaultName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    resourcePrefix: resourcePrefix
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

module userAssignedIdentity '../modules/user-assigned-identity.bicep' = {
  name: 'userAssignedIdentity'
  params: {
    location: location
    name: userAssignedIdentityName
    tags: tags
  }
}

output keyVaultUri string = keyVault.outputs.keyVaultUri
output storageKeyName string = keyVault.outputs.storageKeyName
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
