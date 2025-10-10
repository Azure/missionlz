@description('Resource ID of the existing virtual network')
param vnetResourceId string

var vnetSubscriptionId = split(vnetResourceId, '/')[2]
var vnetResourceGroupName = split(vnetResourceId, '/')[4]
var vnetName = split(vnetResourceId, '/')[8]

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  scope: resourceGroup(vnetSubscriptionId, vnetResourceGroupName)
  name: vnetName
}

output vnetAddressSpace array = vnet.properties.addressSpace.addressPrefixes
output peeringsData object = {
  vnetResourceId: vnetResourceId
  peeringsList: vnet.properties.virtualNetworkPeerings
}
