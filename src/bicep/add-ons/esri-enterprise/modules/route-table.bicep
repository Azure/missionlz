/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param name string
param tags object
param routeTableRouteName string = 'default_route'
param routeTableRouteAddressPrefix string = '0.0.0.0/0'
param routeTableNextHopIpAddress string
param routeTableRouteNextHopType string = 'VirtualAppliance'

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: name
  location: location
  tags: tags[?'Microsoft.Network/routeTables'] ?? {}
  properties: {
    routes: [
      {
        name: routeTableRouteName
        properties: {
          addressPrefix: routeTableRouteAddressPrefix
          nextHopIpAddress: routeTableNextHopIpAddress
          nextHopType: routeTableRouteNextHopType
        }
      }
    ]
  }
}

output id string = routeTable.id
output name string = routeTable.name
