targetScope = 'managementGroup'

@description('Hub Virtual Network Resource Id')
param hubVirtualNetworkResourceId string

@description('Policy set name')
param policySetName string

@description('Policy set display name')
param policySetDisplayName string

@description('Policy set description')
param policySetDescription string

@description('Policy set category')
param policySetCategory string

@description('Management group to assign the policy set')
param targetManagementGroup string

@description('Display name for the policy assignment')
param policyAssignmentDisplayName string

// Load custom policy definitions from JSON files
var customPolicyDefinitions = [
  loadJsonContent('../policy-guardrails/policy-definitions/Append-AppService-httpsonly.json')
  loadJsonContent('../policy-guardrails/policy-definitions/Append-AppService-latestTLS.json')
  loadJsonContent('../policy-guardrails/policy-definitions/Deploy-Custom-Route-Table.json')
]

// Deploy policy definitions
module policyDefinitions './modules/policy-definitions.bicep' = {
  name: 'policyDefinitions'
  scope: managementGroup(targetManagementGroup)
  params: {
    targetManagementGroup: targetManagementGroup
    customPolicyDefinitions: customPolicyDefinitions
  }
}

// Deploy policy set module, which depends on the completion of policyDefinitions module
module policySet './modules/policy-set-creation.bicep' = {
  name: 'policySet-${policySetName}'
  scope: managementGroup(targetManagementGroup)
  params: {
    policySetName: policySetName
    policySetDisplayName: policySetDisplayName
    policySetDescription: policySetDescription
    policySetCategory: policySetCategory
    policyDefinitionIds: policyDefinitions.outputs.policyDefinitionIds
  }
}

// Policy assignment modules
// Create a managed identity
module managedIdentity './modules/user-assigned-identity.bicep' = {
  name: 'deploy-mlzPolicyAssignmentIdentity'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params:{
    identityName: 'mlzPolicyAssignmentIdentity'
    identityLocation: 'usgovvirginia'
  }
}

// Deploy policy assignment module, which depends on the completion of policySet module
module policyAssignment './modules/policy-set-assignment.bicep' = {
  name: 'policyAssignment-${policySetName}'
  scope: managementGroup(targetManagementGroup)
  params: {
    policySetName: policySetName
    policyAssignmentDisplayName: policyAssignmentDisplayName
    policyLocation: 'usgovvirginia'
    policySetId: policySet.outputs.policySetId
    mlzPolicyUserAssignedIdentityId: managedIdentity.outputs.identityResourceId
  }
}

// Assign roles to the managed identity using the role-assignment module
module roleAssignment './modules/role-assignment.bicep' = {
  name: 'roleAssignment-mlzPolicyAssignmentIdentity'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    targetResourceId: resourceId('Microsoft.Resources/resourceGroups', split(hubVirtualNetworkResourceId, '/')[4])
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
    principalId: managedIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Role assignment for policy managed identity'
  }
}
