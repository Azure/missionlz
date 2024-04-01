param containerName string
param location string
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSKU string = 'Standard_GRS'
param tags object
param subnetResourceId string
param blobsPrivateDnsZoneResourceId string
param filePrivateDnsZoneResourceId string
param fileShareName string = 'fileshare'
param useCloudStorage bool
param userAssignedIdentityResourceId string
param keyVaultUri string
param storageEncryptionKeyName string
param resourcePrefix string

var uniqueStorageName = take('${uniqueString(resourceGroup().id)}', 10)
var zones = [
  blobsPrivateDnsZoneResourceId
  filePrivateDnsZoneResourceId
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${resourcePrefix}saesri${uniqueStorageName}'
  location: location
  tags: contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}
  sku: {
    name: storageSKU
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  kind: 'StorageV2'
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


resource fileservice 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = if (useCloudStorage) {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = if (useCloudStorage) {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = if (useCloudStorage) {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = if (useCloudStorage) {
  parent: fileservice
  name: fileShareName
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
  dependsOn: [
  ]
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  parent: blobService
  name: containerName
}

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-04-01' = [for (zone, i) in zones: {
  name: '${resourcePrefix}-esri-pe-${storageAccount.name}-${i}'
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: '${resourcePrefix}-esri-nic-${storageAccount.name}-${i}'
    privateLinkServiceConnections: [
      {
        name: '${resourcePrefix}-esri-pl-${i}'
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
  name: storageAccount.name
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

output cloudStorageAccountCredentialsUserName string = '${storageAccount.name}${(replace((split(storageAccount.properties.primaryEndpoints.blob, 'https://${storageAccount.name}')[1]), '/', ''))}'
output storageAccountName string = storageAccount.name
output storageEndpoint string = storageAccount.properties.primaryEndpoints.blob
