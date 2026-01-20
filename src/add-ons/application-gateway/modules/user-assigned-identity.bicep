@description('Name of the user-assigned identity to create')
param identityName string
@description('Azure region for deployment')
param location string
@description('Tags to apply to the identity')
param tags object = {}

// Create (or update idempotently) the user-assigned identity
resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

output principalId string = uai.properties.principalId
output identityResourceId string = uai.id
