/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param keyVaultName string
param keyVaultPrivateDnsZoneResourceId string
param location string
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param mlzTags object
param roleDefinitionResourceId string
param subnetResourceId string
param tags object
param userAssignedIdentityPrincipalId string

var privateEndpointName = 'pe-${keyVaultName}'

var Secrets = [
  {
    name: 'DomainJoinPassword'
    value: domainJoinPassword
  }
  {
    name: 'DomainJoinUserPrincipalName'
    value: domainJoinUserPrincipalName
  }
  {
    name: 'LocalAdministratorPassword'
    value: localAdministratorPassword
  }
  {
    name: 'LocalAdministratorUsername'
    value: localAdministratorUsername
  }
]

// The Key Vault stores the secrets to deploy virtual machines
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  tags: union(contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}, mlzTags)
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: union(
    contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {},
    mlzTags
  )
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        id: resourceId(
          'Microsoft.Network/privateEndpoints/privateLinkServiceConnections',
          privateEndpointName,
          privateEndpointName
        )
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-${keyVaultName}'
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azure-automation-net'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = [
  for Secret in Secrets: {
    parent: keyVault
    name: Secret.name
    tags: union(contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}, mlzTags)
    properties: {
      value: Secret.value
    }
  }
]

// Gives the selected users rights to get key vault secrets in deployments
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, roleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: roleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output resourceId string = keyVault.id
