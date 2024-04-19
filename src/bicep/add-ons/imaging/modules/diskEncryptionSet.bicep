/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param diskEncryptionSetName string
param principalId string

var roleDefinitionId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader

resource diskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2023-04-02' existing = {
  name: diskEncryptionSetName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: diskEncryptionSet
  name: guid(principalId, roleDefinitionId, diskEncryptionSet.id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
