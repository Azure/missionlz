param location string
param name string
param tags object

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' =  {
  name: name
  location: location
  tags: tags
}

module roleAssignment 'role-assignment.bicep' = {
  name: 'roleAssignmentEncryption'
  params: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')  // Key Vault Crypto Service Encryption User
    targetResourceId: resourceGroup().id
  }
}

output resourceId string = userAssignedIdentity.id
