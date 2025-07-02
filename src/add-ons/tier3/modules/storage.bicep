/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param delimiter string
param deploymentIndex string
param deploymentNameSuffix string
param environmentAbbreviation string
param filesPrivateDnsZoneResourceId string
param hubSubscriptionId string
param hubResourceGroupName string
param logStorageSkuName string
param location string
param mlzTags object
param queuesPrivateDnsZoneResourceId string
param resourceAbbreviations object
param resourceGroupName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param tier object
param workloadShortName string

module customerManagedKeys '../../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${workloadShortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: 'StorageEncryptionKey'
    keyVaultPrivateDnsZoneResourceId: resourceId(
      hubSubscriptionId,
      hubResourceGroupName,
      'Microsoft.Network/privateDnsZones',
      replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
    )
    location: location
    mlzTags: mlzTags
    resourceAbbreviations: resourceAbbreviations
    tags: tags
    tier: tier
  }
}

module storageAccount '../../../modules/storage-account.bicep' = {
  name: 'deploy-sa-log-${tier.name}-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    filesPrivateDnsZoneResourceId: filesPrivateDnsZoneResourceId
    keyVaultUri: customerManagedKeys.outputs.keyVaultUri
    location: location
    mlzTags: mlzTags
    queuesPrivateDnsZoneResourceId: queuesPrivateDnsZoneResourceId
    skuName: logStorageSkuName
    storageEncryptionKeyName: customerManagedKeys.outputs.keyName
    subnetResourceId: subnetResourceId
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    tier: tier
    userAssignedIdentityResourceId: customerManagedKeys.outputs.userAssignedIdentityResourceId
  }
}

output keyVaultName string = customerManagedKeys.outputs.keyVaultName
output keyVaultUri string = customerManagedKeys.outputs.keyVaultUri
output networkInterfaceResourceIds array = union(
  [
    customerManagedKeys.outputs.keyVaultNetworkInterfaceResourceId
  ],
  storageAccount.outputs.networkInterfaceResourceIds
)
output storageAccountResourceId string = storageAccount.outputs.id
output userAssignedIdentityResourceId string = customerManagedKeys.outputs.userAssignedIdentityResourceId
