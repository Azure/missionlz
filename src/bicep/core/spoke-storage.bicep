/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param blobsPrivateDnsZoneResourceId string
param keyVaultUri string
param location string
param logStorageAccountName string
param logStorageAccountNetworkInterfaceNamePrefix string
param logStorageAccountPrivateEndpointNamePrefix string
param logStorageSkuName string
param serviceToken string
param storageEncryptionKeyName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param userAssignedIdentityResourceId string

module storageAccount '../modules/storage-account.bicep' = {
  name: 'storage'
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    keyVaultUri: keyVaultUri
    location: location
    serviceToken: serviceToken
    skuName: logStorageSkuName
    storageAccountName: logStorageAccountName
    storageAccountNetworkInterfaceNamePrefix: logStorageAccountNetworkInterfaceNamePrefix
    storageAccountPrivateEndpointNamePrefix: logStorageAccountPrivateEndpointNamePrefix
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: subnetResourceId
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

output ResourceId string = storageAccount.outputs.id
