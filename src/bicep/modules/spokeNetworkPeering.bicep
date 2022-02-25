/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param spokeName string
param spokeResourceGroupName string
param spokeVirtualNetworkName string

param hubVirtualNetworkName string
param hubVirtualNetworkResourceId string

module spokeNetworkPeering './virtualNetworkPeering.bicep' = {
  name: '${spokeName}-to-hub-vnet-peering'
  scope: resourceGroup(spokeResourceGroupName)
  params: {
    name: '${spokeVirtualNetworkName}/to-${hubVirtualNetworkName}'
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}
