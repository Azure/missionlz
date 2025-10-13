targetScope = 'resourceGroup'

@description('Key Vault name')
param keyVaultName string
@description('Role Definition ID (GUID)')
param roleDefinitionId string
@description('Principal ID for assignment')
param principalId string
@description('User Assigned Identity Resource ID (for deterministic GUID)')
param userAssignedIdentityResourceId string
@description('Optional enable flag')
param enable bool = true

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enable) {
  name: guid(kv.id, userAssignedIdentityResourceId, 'kv-secrets-user')
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'ServicePrincipal'
  }
  scope: kv
}

output roleAssignmentId string = enable ? roleAssignment.id : ''
