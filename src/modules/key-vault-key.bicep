/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param keyExpirationInDays int = 30
param keyName string
param keyVaultName string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: keyName
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA' // MODIFIED MLZ: 'RSA-HSM' is newer but RSA is backwards compatible.
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
output keyVaultUri string = vault.properties.vaultUri
