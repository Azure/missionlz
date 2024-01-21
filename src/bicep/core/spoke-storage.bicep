/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param azureBlobsPrivateDnsZoneResourceId string
param keyVaultUri string
param location string
param logStorageAccountName string
param logStorageSkuName string
param storageEncryptionKeyName string
param subnetResourceId string
param tags object
param userAssignedIdentityResourceId string

module storageAccount '../modules/storage-account.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: logStorageAccountName
    location: location
    skuName: logStorageSkuName
    tags: tags
    azureBlobsPrivateDnsZoneResourceId: azureBlobsPrivateDnsZoneResourceId
    keyVaultUri: keyVaultUri
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: subnetResourceId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

output ResourceId string = storageAccount.outputs.id
