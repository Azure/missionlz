@description('Name of the route table to create')
param routeTableName string

@description('Disable BGP route propagation (true = static override behavior). Set to false to allow learned routes).')
param disableBgpRoutePropagation bool = true

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: routeTableName
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
  }
}

output routeTableId string = routeTable.id
