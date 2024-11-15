/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
//param deployIdentity bool
param deploymentNameSuffix string
param filesPrivateDnsZoneResourceId string
param keyVaultUri string
param location string
param logStorageSkuName string
param mlzTags object
param queuesPrivateDnsZoneResourceId string
param resourceGroupNames array
param serviceToken string
param storageEncryptionKeyName string
param tablesPrivateDnsZoneResourceId string
param tags object
param tiers array
param userAssignedIdentityResourceId string

module storageAccount 'storage-account.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-storage-account-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
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
    subnetResourceId: resourceId(tier.subscriptionId, resourceGroupNames[i], 'Microsoft.Network/virtualNetworks/subnets', tier.namingConvention.virtualNetwork, tier.namingConvention.subnet)
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}]

output storageAccountResourceIds array = [for (tier, i) in tiers: storageAccount[i].outputs.id]
