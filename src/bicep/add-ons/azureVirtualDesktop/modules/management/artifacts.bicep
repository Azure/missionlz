param location string
param resourceGroupManagement string
param storageAccountName string
param subscriptionId string
param tags object
param timestamp string
param userAssignedIdentityNamePrefix string

var name = '${userAssignedIdentityNamePrefix}-artifacts'
var roleDefinitionId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

module userAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupManagement)
  name: 'UAI_Artifacts_${timestamp}'
  params: {
    location: location
    name: name
    tags: contains(tags, 'Microsoft.ManagedIdentity/userAssignedIdentities') ? tags['Microsoft.ManagedIdentity/userAssignedIdentities'] : {}
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(name, roleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

output userAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.outputs.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
