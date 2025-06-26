/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param hubVirtualNetworkName string
param resourceGroupName string
param spokeShortName string
param spokeVirtualNetworkResourceId string
param subscriptionId string

module hubToSpokePeering '../modules/virtual-network-peering.bicep' = {
  name: 'peer-hub-to-${spokeShortName}-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    remoteVirtualNetworkResourceId: spokeVirtualNetworkResourceId
    virtualNetworkName: hubVirtualNetworkName
    virtualNetworkPeerName: 'to-${split(spokeVirtualNetworkResourceId, '/')[8]}'
  }
}



