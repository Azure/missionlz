/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
//param deployIdentity bool
param deploymentNameSuffix string
param filesPrivateDnsZoneResourceId string
param keyVaultResourceId string
param location string
param logStorageSkuName string
param mlzTags object
param queuesPrivateDnsZoneResourceId string
param resourceGroupNames array
param tablesPrivateDnsZoneResourceId string
param tags object
param tiers array
param userAssignedIdentityResourceId string

module key '../modules/key-vault-key.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-ra-key-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(split(keyVaultResourceId, '/')[2], split(keyVaultResourceId, '/')[4])
  params: {
    keyName: 'storage-${tier.name}'
    keyVaultName: split(keyVaultResourceId, '/')[8]
  }
}]

module storageAccount 'storage-account.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-storage-account-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    filesPrivateDnsZoneResourceId: filesPrivateDnsZoneResourceId
    keyVaultUri: key[i].outputs.keyVaultUri
    location: location
    mlzTags: mlzTags
    queuesPrivateDnsZoneResourceId: queuesPrivateDnsZoneResourceId
    skuName: logStorageSkuName
    storageEncryptionKeyName: key[i].outputs.keyName
    subnetResourceId: resourceId(tier.subscriptionId, resourceGroupNames[i], 'Microsoft.Network/virtualNetworks/subnets', tier.namingConvention.virtualNetwork, tier.namingConvention.subnet)
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}]

output networkInterfaceResourceIds array = [for (tier, i) in tiers: storageAccount[i].outputs.networkInterfaceResourceIds]
output storageAccountResourceIds array = [for (tier, i) in tiers: storageAccount[i].outputs.id]
