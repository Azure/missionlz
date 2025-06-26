@description('The Key Vault resource ID')
param keyvaultUri string

@description('The name for the managed identity to create and assign to the Application Gateway')
param identityName string

@description('The location for the managed identity')
param location string

@description('Whether to deploy the access policy')
param deployAccessPolicy bool = true

var keyVaultName = split(split(keyvaultUri, '://')[1], '.')[0]

// Create the managed identity for the Application Gateway
resource agwIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Reference the existing Key Vault
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Add access policy if required
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = if (deployAccessPolicy) {
  name: 'add'
  parent: existingKeyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: agwIdentity.properties.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

output identityResourceId string = agwIdentity.id
output principalId string = agwIdentity.properties.principalId
