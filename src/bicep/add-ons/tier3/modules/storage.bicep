/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param filesPrivateDnsZoneResourceId string
param keyVaultUri string
param logStorageSkuName string
param location string
param mlzTags object
param network object
param queuesPrivateDnsZoneResourceId string
param resourceGroupName string
param serviceToken string
param storageEncryptionKeyName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param tier object
param userAssignedIdentityResourceId string

module storageAccount '../../../modules/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup(network.subscriptionId, resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    filesPrivateDnsZoneResourceId: filesPrivateDnsZoneResourceId
    keyVaultUri: keyVaultUri
    location: location
    mlzTags: mlzTags
    queuesPrivateDnsZoneResourceId: queuesPrivateDnsZoneResourceId
    serviceToken: serviceToken
    skuName: logStorageSkuName
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: subnetResourceId
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

output storageAccountResourceId string = storageAccount.outputs.id
