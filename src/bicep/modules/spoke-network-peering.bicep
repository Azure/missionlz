/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param hubVirtualNetworkResourceId string
param resourceGroupName string
param spokeName string
param spokeVirtualNetworkName string
param subscriptionId string

module spokeNetworkPeering '../modules/virtual-network-peering.bicep' = {
  name: '${spokeName}-to-hub-vnet-peering'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
    virtualNetworkName: spokeVirtualNetworkName
    virtualNetworkPeerName: 'to-${split(hubVirtualNetworkResourceId, '/')[8]}'
  }
}
