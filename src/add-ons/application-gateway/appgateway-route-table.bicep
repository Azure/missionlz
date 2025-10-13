// appgateway-route-table.bicep - Minimal route table (placeholder, no routes yet)
@description('Deployment location')
param location string
@description('Deployment name for naming context')
param deploymentName string
@description('Default route next hop IP (Firewall private IP)')
param firewallPrivateIp string
@description('Tags object')
param tags object = {}

resource appgwRouteTable 'Microsoft.Network/routeTables@2024-05-01' = {
	name: '${deploymentName}-appgw-rt'
	location: location
	tags: tags
	properties: {
		disableBgpRoutePropagation: false
		routes: [
			{
				name: 'default-to-firewall'
				properties: {
					addressPrefix: '0.0.0.0/0'
					nextHopType: 'VirtualAppliance'
					nextHopIpAddress: firewallPrivateIp
				}
			}
		]
	}
}

output routeTableId string = appgwRouteTable.id
