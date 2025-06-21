targetScope = 'subscription'

@description('Resource ID of the subnet to attach the NAT Gateway to.')
param subnetResourceId string

@description('Zone for the NAT Gateway. Use "" for no zone, or "1", "2", "3" for specific zones.')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param zone string = ''

@description('TCP idle timeout in minutes for the NAT Gateway.')
@minValue(4)
@maxValue(120)
param tcpIdleTimeout int = 4

@description('The length of the public IP prefix for the NAT Gateway.')
param publicIpPrefixLength int = 30

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

// Extract VNet and resource group/subscription from subnetResourceId
var vnetResourceId = join(take(split(subnetResourceId, '/'), 9), '/')
var vnetName = split(vnetResourceId, '/')[8]
var subnetName = split(subnetResourceId, '/')[10]
var subscriptionId = split(subnetResourceId, '/')[2]
var resourceGroupName = split(subnetResourceId, '/')[4]

// Extract values from vnetName using delimiter "-"
var vnetNameParts = split(vnetName, '-')
var identifier = vnetNameParts[0] // "new"
var environmentAbbreviation = vnetNameParts[1] // "dev"
var networkName = vnetNameParts[3] // "hub"

// Reference the existing VNet resource to get its location
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
  scope: resourceGroup(subscriptionId, resourceGroupName)
}
var location = vnet.location

// Generate names using your naming convention module
module namingConvention '../../../modules/naming-convention.bicep' = {
  name: 'namingConvention-${deploymentNameSuffix}'
  scope: subscription()
  params: {
    delimiter: '-'
    environmentAbbreviation: environmentAbbreviation
    location: location
    networkName: networkName
    identifier:  identifier
    stampIndex: ''
  }
}

// Create the NAT Gateway and Public IP Prefix using your module
module natGatewayModule './nat-gateway.bicep' = {
  name: 'natGateway-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    hubFirewallResourceId: vnetResourceId // Used to derive resource group in the module
    location: location
    zone: zone
    natGatewayName: namingConvention.outputs.names.natGateway
    tcpIdleTimeout: tcpIdleTimeout
    publicIpPrefixLength: publicIpPrefixLength
    publicIpPrefixName: namingConvention.outputs.names.natGatewayPublicIPPrefix
  }
}

// ...existing code...

// Call get-networkinfo.bicep to get subnet information
module getSubnetInfo './get-subnetinfo.bicep' = {
  name: 'getSubnetInfo-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    vnetName: vnetName
    subnetName: subnetName
  }
}

module attachNatGatewayToSubnet './attach-natgw-to-subnet.bicep' = {
  name: 'attachNatGatewayToSubnet-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    vnetName: getSubnetInfo.outputs.vnetName
    subnetName: getSubnetInfo.outputs.subnetName
    natGatewayId: natGatewayModule.outputs.natGatewayId
    addressPrefix: getSubnetInfo.outputs.addressPrefix
    defaultOutboundAccess: getSubnetInfo.outputs.defaultOutboundAccess
    privateEndpointNetworkPolicies: contains(getSubnetInfo.outputs, 'privateEndpointNetworkPolicies') && getSubnetInfo.outputs.privateEndpointNetworkPolicies == 'Enabled' ? 'Disabled' : getSubnetInfo.outputs.privateEndpointNetworkPolicies
    delegations: getSubnetInfo.outputs.?delegations ?? []
    networkSecurityGroupId: getSubnetInfo.outputs.?networkSecurityGroupId
    routeTableId: getSubnetInfo.outputs.?routeTableId
    serviceEndpoints: getSubnetInfo.outputs.?serviceEndpoints ?? []
    serviceEndpointPolicies: getSubnetInfo.outputs.?serviceEndpointPolicies ?? []
  }
}

