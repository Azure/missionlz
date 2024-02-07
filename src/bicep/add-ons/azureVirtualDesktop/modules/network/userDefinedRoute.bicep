param azureFirewallIpAddress string
param disableBgpRoutePropagation bool
param location string
param udrName string

resource routeTable 'Microsoft.Network/routeTables@2021-05-01' = {
  name: udrName
  location: location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          hasBgpOverride: false
          nextHopIpAddress: azureFirewallIpAddress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

output name string = routeTable.name
output id string = routeTable.id
