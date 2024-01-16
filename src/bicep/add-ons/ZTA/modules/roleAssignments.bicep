param principalId string

var roleDefinitionIds = [
  'f353d9bd-d4a6-484e-a77a-8050b599b867' // Automation Contributor | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#automation-contributor
  'f1a07417-d97a-45cb-824c-7a7467783830' // Managed Identity Operator | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#managed-identity-operator
  'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader
  '9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#virtual-machine-contributor
]

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefinitionId in roleDefinitionIds: {
  name: guid(principalId, roleDefinitionId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}]
