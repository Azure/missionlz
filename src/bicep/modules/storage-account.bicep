/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param azureBlobsPrivateDnsZoneResourceId string
param keyVaultUri string
param location string
param resourcePrefix string
param skuName string
param storageAccountName string
param storageEncryptionKeyName string
param subnetResourceId string
param tags object
param userAssignedIdentityResourceId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  tags: tags
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'PrivateLink'
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    encryption: {
      identity: {
        userAssignedIdentity: userAssignedIdentityResourceId
      }
      keySource: 'Microsoft.KeyVault'
      keyvaultproperties: {
        keyvaulturi: keyVaultUri
        keyname: storageEncryptionKeyName
      }
      requireInfrastructureEncryption: true
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
        file: {
          keyType: 'Account'
          enabled: true
        }
        queue: {
          keyType: 'Account'
          enabled: true
        }
        table: {
          keyType: 'Account'
          enabled: true
        }
      }
    }
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-05-01' = {
  name: '${replace(storageAccountName, resourcePrefix, '${resourcePrefix}-pe-')}-blob'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: '${replace(storageAccountName, resourcePrefix, '${resourcePrefix}-pe-')}-blob_${guid(storageAccount.id)}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: storageAccountName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: azureBlobsPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

output id string = storageAccount.id
