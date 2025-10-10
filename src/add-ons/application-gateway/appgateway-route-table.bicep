// appgateway-route-table.bicep - Minimal route table (placeholder, no routes yet)
@description('Deployment location')
param location string
@description('Deployment name for naming context')
param deploymentName string
@description('Tags object')
param tags object = {}

resource appgwRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
	name: '${deploymentName}-appgw-rt'
	location: location
	tags: tags
	properties: {
		disableBgpRoutePropagation: false
		routes: []
	}
}

output routeTableId string = appgwRouteTable.id
