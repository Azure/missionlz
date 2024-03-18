@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param keyVaultCertificatesOfficerRoleDefinitionResourceId string
param keyVaultName string
param keyVaultSecretsOfficerRoleDefinitionResourceId string
param keyVaultCryptoOfficerRoleDefinitionResourceId string
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
@secure()
param primarySiteAdministratorAccountPassword string
param primarySiteAdministratorAccountUserName string
param tags object
param userAssignedIdentityPrincipalId string
param subnetResourceId string
param keyVaultPrivateDnsZoneResourceId string
param diskEncryptionKeyExpirationInDays int = 30
param resourcePrefix string

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
  {
    name: 'PrimarySiteAdministratorAccountUserName'
    value: primarySiteAdministratorAccountUserName
  }
  {
    name: 'PrimarySiteAdministratorAccountPassword'
    value: primarySiteAdministratorAccountPassword
  }
]

// var keyVaultOwner = resourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

// The key vault stores the secrets to deploy virtual machines
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
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

resource key_disks 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: keyVault
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
  parent: keyVault
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

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = [for Secret in Secrets: {
  parent: keyVault
  name: Secret.name
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    value: Secret.value
  }
}]

// Gives the selected users rights to get key vault secrets in deployments
resource keyVaultSecretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, keyVaultSecretsOfficerRoleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsOfficerRoleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultCertificatesOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, keyVaultCertificatesOfficerRoleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultCertificatesOfficerRoleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultCryptoOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, keyVaultCryptoOfficerRoleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultCryptoOfficerRoleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${resourcePrefix}-pe-${keyVaultName}'
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: '${resourcePrefix}-nic-${keyVaultName}'
    privateLinkServiceConnections: [
      {
        name: '${resourcePrefix}-pe-${keyVaultName}'
        properties: {
          privateLinkServiceId: keyVault.id
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

output name string = keyVault.name
output resourceId string = keyVault.id
output keyUriWithVersion string = key_disks.properties.keyUriWithVersion
output keyVaultResourceId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output storageKeyName string = key_storageAccounts.name
