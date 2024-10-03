@description('Name of the route table to create')
param routeTableName string 

@description('CIDR prefixes for the route')
param routes array

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: routeTableName
  location: resourceGroup().location
  properties: {
    routes: [for route in routes: {
      name: route.name
      properties: {
        addressPrefix: route.addressPrefix
        nextHopType: route.nextHopType
        nextHopIpAddress: route.nextHopIpAddress
      }
    }]
    disableBgpRoutePropagation: true
  }
}

output routeTableId string = routeTable.id
