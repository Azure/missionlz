/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param hubResourceGroupName string
param hubVirtualNetworkName string
param spokeVirtualNetworkName string
param spokeVirtualNetworkResourceId string

module hubToSpokeVirtualNetworkPeering '../../../modules/virtualNetworkPeering.bicep' = {
  scope: resourceGroup(hubResourceGroupName)
  name: 'hubToSpokeVirtualNetworkPeering'
  params: {
    name: '${hubVirtualNetworkName}/to-${spokeVirtualNetworkName}'
    remoteVirtualNetworkResourceId: spokeVirtualNetworkResourceId
  }
}
