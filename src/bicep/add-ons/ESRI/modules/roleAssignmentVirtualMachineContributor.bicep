param principalId string
param resourceGroupName string

var roleDefinitionId = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(principalId, roleDefinitionId, resourceGroupName)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
