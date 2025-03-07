param identityName string
param identityLocation string

// Create a managed identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: identityLocation
}

output identityResourceId string = managedIdentity.id
output identityPrincipalId string = managedIdentity.properties.principalId
