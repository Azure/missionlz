/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param keyVaultName string
param location string
param mlzTags object
param tags object
param userAssignedIdentityName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' =  {
  name: userAssignedIdentityName
  location: location
  tags: union(contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? tags['Microsoft.ManagedIdentity/userAssignedIdentities'] : {}, mlzTags)
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', keyVaultName)
  scope: keyVault
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')  // Key Vault Crypto Service Encryption User
  }
}

output resourceId string = userAssignedIdentity.id
