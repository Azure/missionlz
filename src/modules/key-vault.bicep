/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param environmentAbbreviation string
param keyExpirationInDays int = 30
param keyName string
param keyVaultName string
param keyVaultNetworkInterfaceName string
param keyVaultPrivateDnsZoneResourceId string
param keyVaultPrivateEndpointName string
param location string
param managementVirtualMachineName string
param subnetResourceId string
param tags object
param userAssignedIdentityClientId string

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
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

module key 'run-command.bicep' = {
  name: 'deploy-key-${keyName}-${environmentAbbreviation}'
  params: {
    location: location
    name: 'New-KeyVaultKey-${keyName}'
    parameters: [
      {
        name: 'KeyExpirationInDays'
        value: keyExpirationInDays
      }
      {
        name: 'KeyName'
        value: keyName
      }
      {
        name: 'KeyVaultUri'
        value: vault.properties.vaultUri
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
    ]
    script: loadTextContent('../artifacts/New-KeyVaultKey.ps1')
    tags: tags
    virtualMachineName: managementVirtualMachineName
  }
}

resource keyInfo 'Microsoft.KeyVault/vaults/keys@2022-07-01' existing = {
  parent: vault
  name: keyName
  dependsOn: [
    key
  ]
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: keyVaultNetworkInterfaceName
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
    key
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
}

output keyName string = key.name
output keyUriWithVersion string = keyInfo.properties.keyUriWithVersion
output keyVaultName string = vault.name
output keyVaultResourceId string = vault.id
output keyVaultUri string = vault.properties.vaultUri
output networkInterfaceResourceId string = privateEndpoint.properties.networkInterfaces[0].id
