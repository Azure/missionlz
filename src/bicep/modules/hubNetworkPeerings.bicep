param hubVirtualNetworkName string
param spokes array

module hubToSpokePeering './virtualNetworkPeering.bicep' = [ for spoke in spokes: {
  name: 'hub-to-${spoke.type}-vnet-peering'
  params: {
    name: '${hubVirtualNetworkName}/to-${spoke.virtualNetworkName}'
    remoteVirtualNetworkResourceId: spoke.virtualNetworkResourceId
  }
}]
