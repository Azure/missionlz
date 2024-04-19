/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param disableBgpRoutePropagation bool
param location string
param mlzTags object
param name string
param routeAddressPrefix string
param routeName string
param routeNextHopIpAddress string
param routeNextHopType string
param tags object

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/routeTables') ? tags['Microsoft.Network/routeTables'] : {}, mlzTags)
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
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
