/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionHostPublicIPAddressAllocationMethod string
param bastionHostPublicIPAddressAvailabilityZones array
param bastionHostPublicIPAddressSkuName string
param bastionHostSubnetResourceId string
param delimiter string
param deploymentNameSuffix string
param location string
param mlzTags object
param tags object
param tier object
param tokens object

module bastionHost '../../../modules/bastion-host.bicep' = {
  name: 'deploy-ra-bastion-host-${deploymentNameSuffix}'
  scope:resourceGroup(tier.subscriptionId, tier.resourceGroupName)
  params: {
    bastionHostSubnetResourceId: bastionHostSubnetResourceId
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.bastionHost, '${delimiter}${tokens.purpose}', '')
    publicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    publicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    publicIPAddressName: replace(tier.namingConvention.bastionHostPublicIPAddress, '${delimiter}${tokens.purpose}', '')
    publicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    tags: tags
  }
}
