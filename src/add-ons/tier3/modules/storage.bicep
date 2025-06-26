/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param deploymentNameSuffix string
param filesPrivateDnsZoneResourceId string
param keyVaultResourceId string
param keyVaultUri string
param logStorageSkuName string
param location string
param mlzTags object
param queuesPrivateDnsZoneResourceId string
param resourceGroupName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param tier object
param userAssignedIdentityResourceId string

module key '../../../modules/key-vault-key.bicep' = {
  name: 'deploy-ra-key-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(split(keyVaultResourceId, '/')[2], split(keyVaultResourceId, '/')[4])
  params: {
    keyName: 'storage-${tier.name}'
    keyVaultName: split(keyVaultResourceId, '/')[8]
  }
}

module storageAccount '../../../modules/storage-account.bicep' = {
  name: 'deploy-sa-log-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    filesPrivateDnsZoneResourceId: filesPrivateDnsZoneResourceId
    keyVaultUri: keyVaultUri
    location: location
    mlzTags: mlzTags
    queuesPrivateDnsZoneResourceId: queuesPrivateDnsZoneResourceId
    skuName: logStorageSkuName
    storageEncryptionKeyName: key.outputs.keyName
    subnetResourceId: subnetResourceId
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

output networkInterfaceResourceIds array = storageAccount.outputs.networkInterfaceResourceIds
output storageAccountResourceId string = storageAccount.outputs.id
