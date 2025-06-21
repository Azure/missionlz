targetScope = 'subscription'

param networkName string
param peerings array

var virtualNetworkResourceId = filter(peerings, peer => contains(peer.name, '-${networkName}-'))[0].properties.remoteVirtualNetwork.id

// Gets the existing MLZ virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(virtualNetworkResourceId, '/')[8]
  scope: resourceGroup(split(virtualNetworkResourceId, '/')[2], split(virtualNetworkResourceId, '/')[4])
}

output addressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
