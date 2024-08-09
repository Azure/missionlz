/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param deployIdentity bool
param deploymentNameSuffix string
param keyVaultUri string
param location string
param logStorageSkuName string
param mlzTags object
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
    keyVaultUri: keyVaultUri
    location: location
    mlzTags: mlzTags
    serviceToken: serviceToken
    skuName: logStorageSkuName
    storageAccountName: tier.namingConvention.storageAccount
    storageAccountNetworkInterfaceNamePrefix: tier.namingConvention.storageAccountNetworkInterface
    storageAccountPrivateEndpointNamePrefix: tier.namingConvention.storageAccountPrivateEndpoint
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: resourceId(tier.subscriptionId, resourceGroupNames[i], 'Microsoft.Network/virtualNetworks/subnets', tier.namingConvention.virtualNetwork, tier.namingConvention.subnet)
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}]

output storageAccountResourceIds array = union([
  resourceId(tiers[0].subscriptionId, resourceGroupNames[0], 'Microsoft.Storage/storageAccounts', tiers[0].namingConvention.storageAccount)
  resourceId(tiers[1].subscriptionId, resourceGroupNames[1], 'Microsoft.Storage/storageAccounts', tiers[1].namingConvention.storageAccount)
  resourceId(tiers[2].subscriptionId, resourceGroupNames[2], 'Microsoft.Storage/storageAccounts', tiers[2].namingConvention.storageAccount)
], deployIdentity ? [
  resourceId(tiers[3].subscriptionId, resourceGroupNames[3], 'Microsoft.Storage/storageAccounts', tiers[3].namingConvention.storageAccount)
] : []
)

