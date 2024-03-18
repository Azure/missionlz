param userAssignedIdentityPrincipalId string
param keyVaultName string

var roleDefinitionId = 'f25e0fa2-a7c8-4377-a976-54943a77a395' // Key Vault Contributor| https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(userAssignedIdentityPrincipalId, roleDefinitionId, keyVault.id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultRoleAssignmentId string =  roleAssignment.id
