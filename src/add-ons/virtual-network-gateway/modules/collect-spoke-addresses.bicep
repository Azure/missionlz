@description('List of spoke VNet resource IDs to collect address spaces from')
param virtualNetworkResourceIdList array

// Reuse retrieve-existing to get vnetAddressSpace for each spoke
module retrieveVnetInfo 'retrieve-existing.bicep' = [for (vnetId, i) in virtualNetworkResourceIdList: {
  name: 'collectVnetInfo-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: vnetId
  }
}]

@description('Array of addressSpaces per spoke VNet, aligned by index to virtualNetworkResourceIdList')
output spokeAddressPrefixSets array = [for (vnetId, i) in virtualNetworkResourceIdList: retrieveVnetInfo[i].outputs.vnetAddressSpace]
