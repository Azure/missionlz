/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
//param deployIdentity bool
param deploymentNameSuffix string
param environmentAbbreviation string
param filesPrivateDnsZoneResourceId string
param keyVaultPrivateDnsZoneResourceId string
param location string
param logStorageSkuName string
param mlzTags object
param queuesPrivateDnsZoneResourceId string
param resourceGroupNames array
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param tiers array

module customerManagedKeys 'customer-managed-keys.bicep' = {
  name: 'deploy-st-cmk-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: 'StorageEncryptionKey'
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: mlzTags
    resourceGroupName: filter(resourceGroupNames, name => contains(name, 'hub'))[0]
    subnetResourceId: subnetResourceId
    tags: tags
    tier: filter(tiers, tier => tier.name == 'hub')[0]
  }
}

@batchSize(1)
module storageAccounts 'storage-account.bicep' = [for (tier, i) in tiers: {
  name: 'deploy-storage-account-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupNames[i])
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    filesPrivateDnsZoneResourceId: filesPrivateDnsZoneResourceId
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    mlzTags: mlzTags
    queuesPrivateDnsZoneResourceId: queuesPrivateDnsZoneResourceId
    skuName: logStorageSkuName
    storageEncryptionKeyName: customerManagedKeys.outputs.keyName
    subnetResourceId: resourceId(tier.subscriptionId, resourceGroupNames[i], 'Microsoft.Network/virtualNetworks/subnets', tier.namingConvention.virtualNetwork, tier.namingConvention.subnet)
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
}]

output keyVaultProperties object = customerManagedKeys.outputs.keyVaultProperties
output networkInterfaceResourceIds array = [for (tier, i) in tiers: storageAccounts[i].outputs.networkInterfaceResourceIds]
output storageAccountResourceIds array = [for (tier, i) in tiers: storageAccounts[i].outputs.id]
