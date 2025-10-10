@description('Name of the route table to create')
param routeTableName string 

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: routeTableName
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: true
  }
}

output routeTableId string = routeTable.id
