/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param deploymentNameSuffix string
param hubVirtualNetworkResourceId string
param resourceGroupName string
param spokeShortName string
param spokeVirtualNetworkName string
param subscriptionId string

module spokeNetworkPeering '../modules/virtual-network-peering.bicep' = {
  name: 'peer-${spokeShortName}-to-hub-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
    virtualNetworkName: spokeVirtualNetworkName
    virtualNetworkPeerName: 'to-${split(hubVirtualNetworkResourceId, '/')[8]}'
  }
}
