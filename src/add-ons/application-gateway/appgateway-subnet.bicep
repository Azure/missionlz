// appgateway-subnet.bicep - ensure AppGateway subnet in existing hub VNet (Scenario A)
// Creates (or ensures) the subnet. Does not attach NSG yet (future extension) and does not set route table (will be separate association step).

@description('Hub VNet resource ID where subnet will be created')
param hubVnetResourceId string
@description('Subnet name for Application Gateway')
param subnetName string = 'AppGateway'
@description('Address prefix for the subnet')
param addressPrefix string = '10.100.0.0/24'
@description('Disable implicit Internet egress for the subnet (set false to harden by default).')
param defaultOutboundAccess bool = false

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
		// Route table & NSG are associated in parent solution; left detached here intentionally.
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
