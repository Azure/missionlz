targetScope = 'subscription'

@description('Resource ID of the Hub virtual network that contains AzureFirewallSubnet.')
param hubVirtualNetworkResourceId string

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

// Derive the AzureFirewallSubnet resource ID from the hub VNet
var subnetResourceId = '${hubVirtualNetworkResourceId}/subnets/AzureFirewallSubnet'

// Extract VNet and resource group/subscription from subnetResourceId
var vnetResourceId = join(take(split(subnetResourceId, '/'), 9), '/')
var vnetName = split(vnetResourceId, '/')[8]
var subnetName = split(subnetResourceId, '/')[10]
var subscriptionId = split(subnetResourceId, '/')[2]
var resourceGroupName = split(subnetResourceId, '/')[4]

// Reference the existing VNet resource to get its location
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
  scope: resourceGroup(subscriptionId, resourceGroupName)
}

// Naming helper inputs
var directionShortNames = {
  east: 'e'
  eastcentral: 'ec'
  north: 'n'
  northcentral: 'nc'
  south: 's'
  southcentral: 'sc'
  west: 'w'
  westcentral: 'wc'
}
var location = vnet.location
var locations = loadJsonContent('../../data/locations.json')[?environment().name] ?? {
  '${location}': {
    abbreviation: directionShortNames[skip(location, length(location) - 4)]
    timeDifference: contains(location, 'east') ? '-5:00' : contains(location, 'west') ? '-8:00' : '0:00'
    timeZone: contains(location, 'east') ? 'Eastern Standard Time' : contains(location, 'west') ? 'Pacific Standard Time' : 'GMT Standard Time'
  }
}

// Extract values from vnetName using delimiter "-" with safe fallbacks
var vnetNameParts = split(vnetName, '-')
var partsLen = length(vnetNameParts)
var identifier = partsLen > 0 ? vnetNameParts[0] : vnetName
var environmentAbbreviation = partsLen > 1 ? vnetNameParts[1] : 'prod'
var networkName = partsLen > 3 ? vnetNameParts[3] : (partsLen > 0 ? vnetNameParts[partsLen - 1] : 'hub')

// Generate names using your naming convention module
module namingConvention '../../modules/naming-convention.bicep' = {
  name: 'namingConvention-${deploymentNameSuffix}'
  scope: subscription()
  params: {
    delimiter: '-'
    environmentAbbreviation: environmentAbbreviation
    identifier:  identifier
    locationAbbreviation: locations[location].abbreviation
    networkName: networkName
    resourceAbbreviations: loadJsonContent('../../data/resource-abbreviations.json')
  }
}

// Create the NAT Gateway and Public IP Prefix
module natGatewayModule './modules/nat-gateway.bicep' = {
  name: 'natGateway-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    hubVirtualNetworkResourceId: vnetResourceId
    location: location
    zone: zone
    natGatewayName: namingConvention.outputs.names.natGateway
    tcpIdleTimeout: tcpIdleTimeout
    publicIpPrefixLength: publicIpPrefixLength
    publicIpPrefixName: namingConvention.outputs.names.natGatewayPublicIPPrefix
  }
}

// Retrieve subnet properties to avoid circular dependency during update
module getSubnetInfo './modules/get-subnetinfo.bicep' = {
  name: 'getSubnetInfo-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    vnetName: vnetName
    subnetName: subnetName
  }
}

// Attach NAT Gateway to AzureFirewallSubnet while preserving properties
module attachNatGatewayToSubnet './modules/attach-natgw-to-subnet.bicep' = {
  name: 'attachNatGatewayToSubnet-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    vnetName: getSubnetInfo.outputs.vnetName
    subnetName: getSubnetInfo.outputs.subnetName
    natGatewayId: natGatewayModule.outputs.natGatewayId
    addressPrefix: getSubnetInfo.outputs.addressPrefix
    delegations: getSubnetInfo.outputs.delegations
    serviceEndpoints: getSubnetInfo.outputs.serviceEndpoints
    serviceEndpointPolicies: getSubnetInfo.outputs.serviceEndpointPolicies
    privateEndpointNetworkPolicies: getSubnetInfo.outputs.privateEndpointNetworkPolicies == 'Enabled' ? 'Disabled' : getSubnetInfo.outputs.privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: getSubnetInfo.outputs.privateLinkServiceNetworkPolicies
    defaultOutboundAccess: getSubnetInfo.outputs.defaultOutboundAccess
    networkSecurityGroupId: getSubnetInfo.outputs.networkSecurityGroupId
    routeTableId: getSubnetInfo.outputs.routeTableId
  }
}
