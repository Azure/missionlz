/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param diskEncryptionKeyExpirationInDays int = 30
param environmentAbbreviation string
param keyVaultPrivateDnsZoneResourceId string
param location string
param mlzTags object
param resourceAbbreviations object
param subnetResourceId string
param tags object
param tier object

var keyVaultPrivateEndpointName = tier.namingConvention.keyVaultPrivateEndpoint

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${resourceAbbreviations.keyVaults}${uniqueString(tier.namingConvention.keyVault, resourceGroup().id)}'
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

resource key_disks 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: 'DiskEncryptionKey'
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA-HSM'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(diskEncryptionKeyExpirationInDays)}D'
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
            timeAfterCreate: 'P${string(diskEncryptionKeyExpirationInDays - 7)}D'
          }
        }
      ]
    }
  }
}

resource key_storageAccounts 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: 'StorageEncryptionKey'
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA-HSM'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(diskEncryptionKeyExpirationInDays)}D'
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
            timeAfterCreate: 'P${string(diskEncryptionKeyExpirationInDays - 7)}D'
          }
        }
      ]
    }
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
  dependsOn: [
    key_disks
    key_storageAccounts
  ]
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
  dependsOn: [
    key_disks
    key_storageAccounts
  ]
}

output keyUriWithVersion string = key_disks.properties.keyUriWithVersion
output keyVaultResourceId string = vault.id
output keyVaultName string = vault.name
output keyVaultUri string = vault.properties.vaultUri
output networkInterfaceResourceId string = privateEndpoint.properties.networkInterfaces[0].id
output storageKeyName string = key_storageAccounts.name
