param diskEncryptionKeyExpirationInDays int = 30
param keyVaultName string
param keyVaultPrivateDnsZoneResourceId string
param location string
param resourcePrefix string
param subnetResourceId string
param tags object

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: true
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
      name: 'standard'
    }
    softDeleteRetentionInDays: 7 
    tenantId: subscription().tenantId
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: replace(keyVaultName, resourcePrefix, '${resourcePrefix}-pe')
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: replace(keyVaultName, resourcePrefix, '${resourcePrefix}-nic')
    privateLinkServiceConnections: [
      {
        name: replace(keyVaultName, resourcePrefix, '${resourcePrefix}-nic')
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
  name: keyVaultName
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

resource key_disks 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: 'DiskEncryptionKey'
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA'
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
    kty: 'RSA'
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

output keyUriWithVersion string = key_disks.properties.keyUriWithVersion
output keyVaultResourceId string = vault.id
output keyVaultUri string = vault.properties.vaultUri
output storageKeyName string = key_storageAccounts.name
