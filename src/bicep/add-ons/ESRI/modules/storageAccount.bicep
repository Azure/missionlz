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
// param subnetResourceId string
// param resourcePrefix string
// param blobsPrivateDnsZoneResourceId string
param fileShareName string = 'fileshare'
param useCloudStorage bool

var uniqueStorageName = take('${uniqueString(resourceGroup().id)}', 10)
// var zones = [
//   blobsPrivateDnsZoneResourceId
// ]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${uniqueStorageName}esri'
  location: location
  tags: contains(tags, 'Microsoft.Storage/storageAccounts') ? tags['Microsoft.Storage/storageAccounts'] : {}
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowedCopyScope: 'PrivateLink'
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
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

output storageEndpoint string = storageAccount.properties.primaryEndpoints.blob
output storageAccountName string = storageAccount.name
output cloudStorageAccountCredentialsUserName string = '${storageAccount.name}${(replace((split(storageAccount.properties.primaryEndpoints.blob, 'https://${storageAccount.name}')[1]), '/', ''))}'
