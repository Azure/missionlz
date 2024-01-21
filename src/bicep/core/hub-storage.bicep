/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param azureBlobsPrivateDnsZoneResourceId string
param keyVaultUri string
param logStorageAccountName string
param logStorageSkuName string
param location string
param resourcePrefix string
param storageEncryptionKeyName string
param subnetResourceId string
param tags object
param userAssignedIdentityResourceId string

module storageAccount '../modules/storage-account.bicep' = {
  name: 'storage'
  params: {
    azureBlobsPrivateDnsZoneResourceId: azureBlobsPrivateDnsZoneResourceId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    keyVaultUri: keyVaultUri
    location: location
    resourcePrefix: resourcePrefix
    skuName: logStorageSkuName
    storageAccountName: logStorageAccountName
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

output storageAccountResourceId string = storageAccount.outputs.id
