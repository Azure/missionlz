targetScope = 'subscription'

param hubResourceGroupName string
param hubVirtualNetworkName string
param spokeNetworks array

module hubToSpokePeering './virtualNetworkPeering.bicep' = [ for spoke in spokeNetworks: {
  scope: resourceGroup(hubResourceGroupName)
  name: 'hubTo${spoke.type}VirtualNetworkPeering'
  params: {
    name: '${hubVirtualNetworkName}/to-${spoke.virtualNetworkName}'
    remoteVirtualNetworkResourceId: spoke.virtualNetworkResourceId
  }
}]
