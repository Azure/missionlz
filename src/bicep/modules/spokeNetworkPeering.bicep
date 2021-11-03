targetScope = 'subscription'

param spokeType string
param spokeResourceGroupName string
param spokeVirtualNetworkName string

param hubVirtualNetworkName string
param hubVirtualNetworkResourceId string

module spokeNetworkPeering './virtualNetworkPeering.bicep' = {
  name: '${spokeType}-to-hub-vnet-peering'
  scope: resourceGroup(spokeResourceGroupName)
  params: {
    name: '${spokeVirtualNetworkName}/to-${hubVirtualNetworkName}'
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}
