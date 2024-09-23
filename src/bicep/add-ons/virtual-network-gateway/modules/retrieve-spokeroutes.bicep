@description('The resource ID of the existing route table')
param routeTableId string

// Retrieve the existing route table details
var routeTableInfo = list(routeTableId, '2021-02-01')

// Define outputs directly from the retrieved route table info
output routeTableOutput object = {
  routeTableId: routeTableId
  routes: routeTableInfo.properties.routes
}
