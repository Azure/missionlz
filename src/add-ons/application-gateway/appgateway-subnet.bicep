// appgateway-subnet.bicep - ensure AppGateway subnet in existing hub VNet (Scenario A)
// Creates (or ensures) the subnet. Does not attach NSG yet (future extension) and does not set route table (will be separate association step).

@description('Deployment location (not directly used, kept for consistency)')
param location string
@description('Hub VNet resource ID where subnet will be created')
param hubVnetResourceId string
@description('Subnet name for Application Gateway')
param subnetName string = 'AppGateway'
@description('Address prefix for the subnet')
param addressPrefix string = '10.100.0.0/24'
@description('Tags object (unused; retained for alignment)')
param tags object = {}

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
	}
}

output subnetId string = appGatewaySubnet.id
