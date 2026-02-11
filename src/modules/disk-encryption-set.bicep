/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param diskEncryptionSetName string
param keyVaultName string

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' existing = {
  name: diskEncryptionSetName
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment_keyVaultCryptoServiceEncryptionUser_DES 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(diskEncryptionSet.name, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', vault.id)
  scope: vault
  properties: {
    principalId: diskEncryptionSet!.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
  }
}

output resourceId string = diskEncryptionSet.id
