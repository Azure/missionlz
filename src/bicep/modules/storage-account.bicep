/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param blobsPrivateDnsZoneResourceId string
param keyVaultUri string
param location string
param mlzTags object
param serviceToken string
param skuName string
param storageAccountName string
param storageAccountNetworkInterfaceNamePrefix string
param storageAccountPrivateEndpointNamePrefix string
param storageEncryptionKeyName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param userAssignedIdentityResourceId string

var zones = [
  blobsPrivateDnsZoneResourceId
  tablesPrivateDnsZoneResourceId
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: union(contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}, mlzTags)
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

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-04-01' = [for (zone, i) in zones: {
  name: replace(storageAccountPrivateEndpointNamePrefix, serviceToken, split(split(zone, '/')[8], '.')[1])
  location: location
  tags: union(contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}, mlzTags)
  properties: {
    customNetworkInterfaceName: replace(storageAccountNetworkInterfaceNamePrefix, serviceToken, split(split(zone, '/')[8], '.')[1])
    privateLinkServiceConnections: [
      {
        name: replace(storageAccountPrivateEndpointNamePrefix, serviceToken, split(split(zone, '/')[8], '.')[1])
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            split(split(zone, '/')[8], '.')[1]
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}]

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = [for (zone, i) in zones: {
  parent: privateEndpoints[i]
  name: storageAccountName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          #disable-next-line use-resource-id-functions
          privateDnsZoneId: zone
        }
      }
    ]
  }
}]

output id string = storageAccount.id
