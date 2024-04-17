/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deploymentNameSuffix string
param diskEncryptionSetName string
param keyUrl string
param keyVaultResourceId string
param location string
param mlzTags object
param tags object

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' = {
  name: diskEncryptionSetName
  location: location
  tags: union(contains(tags, 'Microsoft.Compute/diskEncryptionSets') ? tags['Microsoft.Compute/diskEncryptionSets'] : {}, mlzTags)
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    activeKey: {
      sourceVault: {
        id: keyVaultResourceId
      }
      keyUrl: keyUrl
    }
    encryptionType: 'EncryptionAtRestWithPlatformAndCustomerKeys'
    rotationToLatestKeyVersionEnabled: true
  }
}

module roleAssignment 'role-assignment.bicep' = {
  name: 'assign-role-disk-encryption-set-ops-${deploymentNameSuffix}'
  params: {
    principalId: diskEncryptionSet.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions','e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
    targetResourceId: resourceGroup().id
  }
}

output resourceId string = diskEncryptionSet.id
