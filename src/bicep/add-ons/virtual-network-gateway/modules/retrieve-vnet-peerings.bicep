@description('The resource ID of the existing hub virtual network')
param vnetResourceId string

// Define the existing VNet resource
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: last(split(vnetResourceId, '/'))
  scope: resourceGroup(split(vnetResourceId, '/')[2], split(vnetResourceId, '/')[4])
}

// Retrieve the list of peerings from the VNet
output peeringsData object = {
  vnetResourceId: vnetResourceId
  peeringsList: vnet.properties.virtualNetworkPeerings
}
