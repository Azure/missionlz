/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param environmentAbbreviation string
param keyExpirationInDays int = 30
param keyName string
param keyVaultPrivateDnsZoneResourceId string
param location string
param mlzTags object
param resourceAbbreviations object
param subnetResourceId string
param tags object
param tier object
param workload string = ''

var keyVaultPrivateEndpointName = tier.namingConvention.keyVaultPrivateEndpoint

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${resourceAbbreviations.keyVaults}${uniqueString(tier.namingConvention.keyVault, resourceGroup().id, workload)}'
  location: location
  tags: union(tags[?'Microsoft.KeyVault/vaults'] ?? {}, mlzTags)
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
    sku: {
      family: 'A'
      name: 'premium'
    }
    softDeleteRetentionInDays: environmentAbbreviation == 'dev' || environmentAbbreviation == 'test' ? 7 : 90
    tenantId: subscription().tenantId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  tags: union(tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: tier.namingConvention.keyVaultNetworkInterface
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: vault.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: keyName
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA-HSM'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(keyExpirationInDays)}D'
      }
      lifetimeActions: [
        {
          action: {
            type: 'Notify'
          }
          trigger: {
            timeBeforeExpiry: 'P10D'
          }
        }
        {
          action: {
            type: 'Rotate'
          }
          trigger: {
            timeAfterCreate: 'P${string(keyExpirationInDays - 7)}D'
          }
        }
      ]
    }
  }
}

output keyName string = key.name
output keyUriWithVersion string = key.properties.keyUriWithVersion
output keyVaultName string = vault.name
output keyVaultResourceId string = vault.id
output keyVaultUri string = vault.properties.vaultUri
output networkInterfaceResourceId string = privateEndpoint.properties.networkInterfaces[0].id
