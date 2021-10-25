param name string
param location string
param tags object = {}

param routeName string
param routeAddressPrefix string
param routeNextHopIpAddress string
param routeNextHopType string

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    routes: [
      {
        name: routeName
        properties: {
          addressPrefix: routeAddressPrefix
          nextHopIpAddress: routeNextHopIpAddress
          nextHopType: routeNextHopType
        }
      }
    ]
  }
}

output id string = routeTable.id
output name string = routeTable.name
