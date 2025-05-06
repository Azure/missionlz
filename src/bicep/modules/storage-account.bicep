/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param blobsPrivateDnsZoneResourceId string
param delimiter string
param filesPrivateDnsZoneResourceId string
param keyVaultUri string
param location string
param mlzTags object
param queuesPrivateDnsZoneResourceId string
param skuName string
param storageEncryptionKeyName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param tier object
param userAssignedIdentityResourceId string

var  subResources = [
  {
    id: blobsPrivateDnsZoneResourceId
    nic: '${tier.namingConvention.storageAccountNetworkInterface}${delimiter}blob'
    pe: '${tier.namingConvention.storageAccountPrivateEndpoint}${delimiter}blob'
  }
  {
    id: filesPrivateDnsZoneResourceId
    nic: '${tier.namingConvention.storageAccountNetworkInterface}${delimiter}file'
    pe: '${tier.namingConvention.storageAccountPrivateEndpoint}${delimiter}file'
  }
  {
    id: queuesPrivateDnsZoneResourceId
    nic: '${tier.namingConvention.storageAccountNetworkInterface}${delimiter}queue'
    pe: '${tier.namingConvention.storageAccountPrivateEndpoint}${delimiter}queue'
  }
  {
    id: tablesPrivateDnsZoneResourceId
    nic: '${tier.namingConvention.storageAccountNetworkInterface}${delimiter}table'
    pe: '${tier.namingConvention.storageAccountPrivateEndpoint}${delimiter}table'
  }
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: uniqueString(tier.namingConvention.storageAccount, resourceGroup().id)
  location: location
  tags: union(tags[?'Microsoft.Storage/storageAccounts'] ?? {}, mlzTags)
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
    allowSharedKeyAccess: false
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

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-04-01' = [for (resource, i) in subResources: {
  name: resource.pe
  location: location
  tags: union(tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: resource.nic
    privateLinkServiceConnections: [
      {
        name: resource.pe
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            split(split(resource.id, '/')[8], '.')[1]
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}]

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = [for (resource, i) in subResources: {
  parent: privateEndpoints[i]
  name: storageAccount.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          #disable-next-line use-resource-id-functions
          privateDnsZoneId: resource.id
        }
      }
    ]
  }
}]

output id string = storageAccount.id
output networkInterfaceResourceIds array = [for (resource, i) in subResources: privateEndpoints[i].properties.networkInterfaces[0].id]
