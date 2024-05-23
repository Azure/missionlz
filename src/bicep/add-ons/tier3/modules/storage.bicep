/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param keyVaultUri string
param logStorageSkuName string
param location string
param mlzTags object
param network object
param resourceGroupName string
param serviceToken string
param storageEncryptionKeyName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param userAssignedIdentityResourceId string

module storageAccount '../../../modules/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroup(network.subscriptionId, resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    keyVaultUri: keyVaultUri
    location: location
    mlzTags: mlzTags
    serviceToken: serviceToken
    skuName: logStorageSkuName
    storageAccountName: network.namingConvention.storageAccount
    storageAccountNetworkInterfaceNamePrefix: network.namingConvention.storageAccountNetworkInterface
    storageAccountPrivateEndpointNamePrefix: network.namingConvention.storageAccountPrivateEndpoint
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: subnetResourceId
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

output storageAccountResourceId string = storageAccount.outputs.id
