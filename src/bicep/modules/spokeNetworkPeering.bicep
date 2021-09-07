targetScope = 'subscription'

param spokeResourceGroupName string
param spokeVirtualNetworkName string

param hubVirtualNetworkName string
param hubVirtualNetworkResourceId string

module spokeNetworkPeering './virtualNetworkPeering.bicep' = {
  scope: resourceGroup(spokeResourceGroupName)
  name: 'spokeNetworkPeering'
  params: {
    name: '${spokeVirtualNetworkName}/to-${hubVirtualNetworkName}'
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}
