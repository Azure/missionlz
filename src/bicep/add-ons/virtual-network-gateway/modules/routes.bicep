@description('Name of the route table to create')
param routeTableName string 

@description('Name of the route')
param routeName string

@description('CIDR prefixes for the route')
param addressSpace array

@description('The next hop type for the route')
param nextHopType string

@description('The next hop IP address for the route')
param nextHopIpAddress string

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' existing = {
  name: routeTableName
  scope: resourceGroup()
}

// Loop over the address spaces and create routes
resource routes 'Microsoft.Network/routeTables/routes@2023-04-01' = [for (cidr, i) in addressSpace: {
  parent: routeTable
  name: '${routeName}-${i}'
  properties: {
    addressPrefix: cidr
    nextHopType: nextHopType
    nextHopIpAddress: nextHopIpAddress != '' ? nextHopIpAddress : null
  }
}]
