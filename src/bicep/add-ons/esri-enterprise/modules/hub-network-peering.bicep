/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'resourceGroup'

param hubResourceGroupName string
param hubVirtualNetworkName string
param spokeVirtualNetworkName string
param spokeVirtualNetworkResourceId string

module hubToSpokeVirtualNetworkPeering '../../../modules/virtual-network-peering.bicep' = {
  scope: resourceGroup(hubResourceGroupName)
  name: 'hubToSpokeVirtualNetworkPeering'
  params: {
    name: '${hubVirtualNetworkName}/to-${spokeVirtualNetworkName}'
    remoteVirtualNetworkResourceId: spokeVirtualNetworkResourceId
  }
}
