/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param deployIdentity bool
param deploymentNameSuffix string
param keyVaultUri string
param logStorageSkuName string
param location string
param networks array
param serviceToken string
param storageEncryptionKeyName string
param tablesPrivateDnsZoneResourceId string
param tags object
param userAssignedIdentityResourceId string

module storageAccount 'storage-account.bicep' = [for (network, i) in networks: {
  name: 'deploy-storage-account-${network.name}-${deploymentNameSuffix}'
  scope: resourceGroup(network.subscriptionId, network.resourceGroupName)
  params: {
    blobsPrivateDnsZoneResourceId: blobsPrivateDnsZoneResourceId
    keyVaultUri: keyVaultUri
    location: location
    serviceToken: serviceToken
    skuName: logStorageSkuName
    storageAccountName: network.logStorageAccountName
    storageAccountNetworkInterfaceNamePrefix: network.logStorageAccountNetworkInterfaceNamePrefix
    storageAccountPrivateEndpointNamePrefix: network.logStorageAccountPrivateEndpointNamePrefix
    storageEncryptionKeyName: storageEncryptionKeyName
    subnetResourceId: resourceId(network.subscriptionId, network.resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', network.virtualNetworkName, network.subnetName)
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}]

output storageAccountResourceIds array = union([
  resourceId(networks[0].subscriptionId, networks[0].resourceGroupName, 'Microsoft.Storage/storageAccounts', networks[0].logStorageAccountName)
  resourceId(networks[1].subscriptionId, networks[1].resourceGroupName, 'Microsoft.Storage/storageAccounts', networks[1].logStorageAccountName)
  resourceId(networks[2].subscriptionId, networks[2].resourceGroupName, 'Microsoft.Storage/storageAccounts', networks[2].logStorageAccountName)
], deployIdentity ? [
  resourceId(networks[3].subscriptionId, networks[3].resourceGroupName, 'Microsoft.Storage/storageAccounts', networks[3].logStorageAccountName)
] : []
)

