@description('The list of peerings to update')
param peeringsList array

@description('The resource ID of the existing virtual network')
param vnetResourceId string

// Extract the virtual network name from the resource ID
var vnetName = last(split(vnetResourceId, '/'))

// Generate the list of updated peerings
var updatedPeerings = [for peering in peeringsList: {
  name: last(split(peering.id, '/')) // Extract the peering name from the ID
  properties: {
    allowGatewayTransit: contains(vnetName, '-hub-') ? true : peering.properties.allowGatewayTransit
    useRemoteGateways: !contains(vnetName, '-hub-') ? true : peering.properties.useRemoteGateways
    // allowGatewayTransit: contains(split(peering.id, '/')[8], '-hub-') ? true : peering.properties.allowGatewayTransit
    // useRemoteGateways: !contains(split(peering.id, '/')[8], '-hub-') ? true : peering.properties.useRemoteGateways
    allowForwardedTraffic: peering.properties.allowForwardedTraffic == null ? true : peering.properties.allowForwardedTraffic // Preserve existing value or set to true
    remoteVirtualNetwork: peering.properties.remoteVirtualNetwork
  }
}]

// Define the parent virtual network resource
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: vnetName
}

// Create or update the peerings within the virtual network context
resource peeringUpdates 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = [for (peering, i) in updatedPeerings: {
  parent: vnet
  name: peering.name
  properties: peering.properties
}]


