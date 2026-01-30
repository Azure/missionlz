targetScope = 'subscription'

@description('A suffix to use for naming deployments uniquely. Default value = "utcNow()".')
param deploymentNameSuffix string = utcNow()

@allowed([
  'dev'
  'prod'
  'test'
])
@description('[dev/prod/test] The abbreviation for the target environment.')
param environmentAbbreviation string = 'dev'

@description('Resource ID of the Hub virtual network that contains AzureFirewallSubnet.')
param hubVirtualNetworkResourceId string

@minLength(1)
@maxLength(5)
@description('1-5 alphanumeric characters without whitespace, used to name resources and generate uniqueness for resources within your subscription. Ideally, the value should represent an organization, department, or business unit.')
param identifier string

@description('The length of the public IP prefix for the NAT Gateway.')
param publicIpPrefixLength int = 30

@description('TCP idle timeout in minutes for the NAT Gateway.')
@minValue(4)
@maxValue(120)
param tcpIdleTimeout int = 4

@description('Zone for the NAT Gateway. Use "" for no zone, or "1", "2", "3" for specific zones.')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param zone string = ''

// Extract VNet and resource group/subscription from subnetResourceId
var resourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var subnetName = split(hubVirtualNetworkResourceId, '/')[10]
var subscriptionId = split(hubVirtualNetworkResourceId, '/')[2]
var virtualNetworkName = split(hubVirtualNetworkResourceId, '/')[8]

// Reference the existing VNet resource to get its location
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(subscriptionId, resourceGroupName)
}

module logic '../../modules/logic.bicep' = {
  name: 'logic-${deploymentNameSuffix}'
  params: {
    delimiter: '-'
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    identifier: identifier
    location: virtualNetwork.location
    networks: [
      {
        name: 'hub'
        shortName: 'hub'
        subscriptionId: subscriptionId
      }
    ]
  }
}

// Create the NAT Gateway and Public IP Prefix
module natGatewayModule './modules/nat-gateway.bicep' = {
  name: 'natGateway-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    location: virtualNetwork.location
    zone: zone
    natGatewayName: logic.outputs.tiers[0].namingConvention.natGateway
    tcpIdleTimeout: tcpIdleTimeout
    publicIpPrefixLength: publicIpPrefixLength
    publicIpPrefixName: logic.outputs.tiers[0].namingConvention.natGatewayPublicIPPrefix
  }
}

// Retrieve subnet properties to avoid circular dependency during update
module getSubnetInfo './modules/get-subnetinfo.bicep' = {
  name: 'getSubnetInfo-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    vnetName: virtualNetworkName
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
