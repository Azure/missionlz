param location string
param name string
param tags object

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' =  {
  name: name
  location: location
  tags: tags
}

output clientId string = userAssignedIdentity.properties.clientId
output resourceId string = userAssignedIdentity.id
output principalId string = userAssignedIdentity.properties.principalId
