@description('The list of address prefixes for routes to add to the route table')
param localAddressPrefixList array

@description('The resource ID of the existing route table')
param routeTableId string

// Extract the route table name from the resource ID
var routeTableName = last(split(routeTableId, '/'))

// Reference the existing route table
resource routeTable 'Microsoft.Network/routeTables@2021-02-01' existing = {
  name: routeTableName
}

// Add the routes to the route table
resource routeUpdates 'Microsoft.Network/routeTables/routes@2021-02-01' = [for (localAddressPrefix, index) in localAddressPrefixList: {
  name: 'vpnRoute${index}'
  parent: routeTable
  properties: {
    addressPrefix: localAddressPrefix
    nextHopType: 'VirtualNetworkGateway'
    nextHopIpAddress: ''
  }
}]
