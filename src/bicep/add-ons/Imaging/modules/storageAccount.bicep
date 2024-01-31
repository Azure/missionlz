param principalId string
param storageAccountResourceId string

var roleDefinitionId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-reader

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: split(storageAccountResourceId, '/')[8]
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(principalId, roleDefinitionId, storageAccountResourceId)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
