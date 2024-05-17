/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param hubVirtualNetworkName string
param resourceGroupName string
param spokeName string
param spokeVirtualNetworkResourceId string
param subscriptionId string

module hubToSpokePeering '../modules/virtual-network-peering.bicep' = {
  name: 'hub-to-${spokeName}-vnet-peering'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    remoteVirtualNetworkResourceId: spokeVirtualNetworkResourceId
    virtualNetworkName: hubVirtualNetworkName
    virtualNetworkPeerName: 'to-${split(spokeVirtualNetworkResourceId, '/')[8]}'
  }
}



