/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param hubVirtualNetworkName string
param spokes array

module hubToSpokePeering '../modules/virtual-network-peering.bicep' = [ for spoke in spokes: {
  name: 'hub-to-${spoke.type}-vnet-peering'
  params: {
    name: '${hubVirtualNetworkName}/to-${spoke.virtualNetworkName}'
    remoteVirtualNetworkResourceId: spoke.virtualNetworkResourceId
  }
}]
