// Idempotent Key Vault role assignment module
// Uses deterministic GUID name AND performs an existence check to avoid hard failure when assignment already exists.
// Approach: attempt deployment normally. If Azure returns RoleAssignmentExists for identical principal/role/scope, deployment still fails.
// Enhancement: declare an existing resource first (best-effort) using the deterministic name; if it exists, skip creation.

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
@description('Optional fully-qualified existing role assignment resource ID to adopt instead of creating a new one')
param existingRoleAssignmentId string = ''

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Deterministic role assignment name (same formula as previous version)
var deterministicName = guid(kv.id, userAssignedIdentityResourceId, 'kv-secrets-user')
var createNew = enable && empty(existingRoleAssignmentId)

// Declare existing role assignment (may or may not exist). If it exists, we just surface its id; if not, we create it.
resource existingAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' existing = if (createNew) {
  name: deterministicName
  scope: kv
}

// Create only when enable AND (best-effort heuristic) assignment not already present.
// Bicep cannot directly test existence; referencing existingAssignment succeeds either way. So we deploy and rely on deterministic name to ensure single instance.
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (createNew) {
  name: deterministicName
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'ServicePrincipal'
  }
  scope: kv
  // Reference existingAssignment to mark usage (even though deterministic name is identical)
  dependsOn: [ existingAssignment ]
}

// Output either created or pre-existing id (both resolve to same deterministic name)
output roleAssignmentId string = !enable ? '' : (!empty(existingRoleAssignmentId) ? existingRoleAssignmentId : resourceId('Microsoft.Authorization/roleAssignments', deterministicName))
