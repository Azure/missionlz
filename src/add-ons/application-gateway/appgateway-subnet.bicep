// appgateway-subnet.bicep - ensure AppGateway subnet in existing hub VNet (Scenario A)
// Single authoritative subnet definition INCLUDING optional NSG + required route table association (Option A consolidation).

@description('Hub VNet resource ID where subnet will be created')
param hubVnetResourceId string
@description('Subnet name for Application Gateway')
param subnetName string = 'AppGateway'
@description('Address prefix for the subnet')
param addressPrefix string = '10.100.0.0/24'
@description('Set to false (default) to disable implicit Internet egress for the subnet (requires explicit UDR via Firewall).')
param defaultOutboundAccess bool = false
@description('Disable private endpoint network policies on this subnet (prevents creation of Private Endpoints here).')
param disablePrivateEndpointNetworkPolicies bool = true
@description('Route table resource ID to associate to the subnet.')
param routeTableId string
@description('Optional Network Security Group resource ID (empty string for none).')
param nsgId string = ''

// Derive vNet name from resource ID
var vnetName = last(split(hubVnetResourceId, '/'))

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
	name: vnetName
}

resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
	name: subnetName
	parent: hubVnet
	properties: {
		addressPrefix: addressPrefix
		// Harden egress: deny implicit Internet access; explicit UDR + Firewall path required for outbound
		defaultOutboundAccess: defaultOutboundAccess
		privateEndpointNetworkPolicies: disablePrivateEndpointNetworkPolicies ? 'Disabled' : 'Enabled'
		// Direct associations (single definition pattern)
		networkSecurityGroup: empty(nsgId) ? null : {
			id: nsgId
		}
		routeTable: {
			id: routeTableId
		}
		// Delegation required for Application Gateway Network Isolation feature (enables UDR to VirtualAppliance for 0.0.0.0/0)
		// Ref: https://learn.microsoft.com/azure/application-gateway/application-gateway-private-deployment#register-the-feature
		delegations: [
			{
				name: 'appgwDelegation'
				properties: {
					serviceName: 'Microsoft.Network/applicationGateways'
				}
			}
		]
	}
}

output subnetId string = appGatewaySubnet.id
