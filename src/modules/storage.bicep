/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param delimiter string
//param deployIdentity bool
param deploymentNameSuffix string
param environmentAbbreviation string
param location string
param logStorageSkuName string
param mlzTags object
param privateDnsZoneResourceIds object
param purpose string
param resourceAbbreviations object
param tags object
param tiers array
param tokens object

var resourceGroupName = filter(tiers, tier => tier.name == 'hub')[0].resourceGroupName
var subscriptionId = filter(tiers, tier => tier.name == 'hub')[0].subscriptionId

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-st-cmk-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: 'StorageEncryptionKey'
    keyVaultPrivateDnsZoneResourceId: privateDnsZoneResourceIds.keyVault
    location: location
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: filter(tiers, tier => tier.name == 'hub')[0].subnetResourceId
    tags: tags
    tier: filter(tiers, tier => tier.name == 'hub')[0]
    tokens: tokens
    type: 'storageAccount'
  }
}

@batchSize(1)
module storageAccounts 'storage-account.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-storage-account-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: privateDnsZoneResourceIds.blob
    delimiter: delimiter
    filesPrivateDnsZoneResourceId: privateDnsZoneResourceIds.file
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    mlzTags: mlzTags
    purpose: purpose
    queuesPrivateDnsZoneResourceId: privateDnsZoneResourceIds.queue
    skuName: logStorageSkuName
    storageEncryptionKeyName: customerManagedKeys.outputs.keyName
    subnetResourceId: tier.subnetResourceId
    tablesPrivateDnsZoneResourceId: privateDnsZoneResourceIds.table
    tags: tags
    tier: tier
    tokens: tokens
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
}]

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = [for (tier, i) in tiers: storageAccounts[i].outputs.networkInterfaceResourceIds]
output storageAccountResourceIds array = [for (tier, i) in tiers: storageAccounts[i].outputs.id]
