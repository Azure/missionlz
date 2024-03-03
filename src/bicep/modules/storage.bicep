/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
targetScope = 'subscription'

param blobsPrivateDnsZoneResourceId string
param deployIdentity bool
param keyVaultUri string
param logStorageSkuName string
param location string
param networks array
param serviceToken string
param storageEncryptionKeyName string
param subnetResourceId string
param tablesPrivateDnsZoneResourceId string
param tags object
param userAssignedIdentityResourceId string

module storageAccount 'storage-account.bicep' = [for (network, i) in networks: {
  name: 'storage'
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
    subnetResourceId: subnetResourceId
    tablesPrivateDnsZoneResourceId: tablesPrivateDnsZoneResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}]

output storageAccountResourceIds array = union([
  storageAccount[0].outputs.id
  storageAccount[1].outputs.id
  storageAccount[2].outputs.id
], deployIdentity ? [
  storageAccount[3].outputs.id
] : []
)

