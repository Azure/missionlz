targetScope = 'managementGroup'

@description('Target management group Id')
param targetManagementGroup string

@description('Array of custom policy definitions')
param customPolicyDefinitions array

resource policyDefinitions 'Microsoft.Authorization/policyDefinitions@2023-04-01' = [for policy in customPolicyDefinitions: {
  name: policy.name
  properties: policy.properties
}]

// Corrected output with resourceId generation
output policyDefinitionIds array = [
  for policy in customPolicyDefinitions: '/providers/Microsoft.Management/managementGroups/${targetManagementGroup}/providers/Microsoft.Authorization/policyDefinitions/${policy.name}'
]
