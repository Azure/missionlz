/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

//param deployIdentity bool
param deploymentNameSuffix string
param environmentAbbreviation string
param location string
param logStorageSkuName string
param privateDnsZoneResourceIds object
param tags object
param tiers array

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-st-cmk-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: 'StorageEncryptionKey'
    keyVaultPrivateDnsZoneResourceId: privateDnsZoneResourceIds.keyVault
    location: location
    tags: tags
    tier: filter(tiers, tier => tier.name == 'hub')[0]
  }
}

@batchSize(1)
module storageAccounts 'storage-account.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-storage-account-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: privateDnsZoneResourceIds.blob
    filesPrivateDnsZoneResourceId: privateDnsZoneResourceIds.file
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    mlzTags: tier.mlzTags
    queuesPrivateDnsZoneResourceId: privateDnsZoneResourceIds.queue
    skuName: logStorageSkuName
    storageEncryptionKeyName: customerManagedKeys.outputs.keyName
    subnetResourceId: resourceId(tier.subscriptionId, tier.resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', tier.namingConvention.virtualNetwork, tier.namingConvention.subnet)
    tablesPrivateDnsZoneResourceId: privateDnsZoneResourceIds.table
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
}]

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = [for (tier, i) in tiers: storageAccounts[i].outputs.networkInterfaceResourceIds]
output storageAccountResourceIds array = [for (tier, i) in tiers: storageAccounts[i].outputs.id]
