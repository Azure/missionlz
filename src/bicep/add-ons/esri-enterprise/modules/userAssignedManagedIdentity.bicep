param location string
param name string
param tags object

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name
  location: location
  tags: tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}
}

output clientId string = userAssignedIdentity.properties.clientId
output name string = userAssignedIdentity.name
output principalId string = userAssignedIdentity.properties.principalId
output resourceId string = userAssignedIdentity.id
