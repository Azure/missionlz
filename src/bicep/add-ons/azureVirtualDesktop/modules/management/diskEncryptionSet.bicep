param diskEncryptionSetName string
param keyVaultResourceId string
param keyUrl string
param location string
param tags object
param timestamp string

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' = {
  name: diskEncryptionSetName
  location: location
  tags: tags
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

module roleAssignment '../common/roleAssignment.bicep' = {
  name: 'RoleAssignment_Encryption_${timestamp}'
  params: {
    PrincipalId: diskEncryptionSet.identity.principalId
    PrincipalType: 'ServicePrincipal'
    RoleDefinitionId: 'e147488a-f6f5-4113-8e2d-b22465e65bf6' // Key Vault Crypto Service Encryption User
  }
}

output resourceId string = diskEncryptionSet.id
