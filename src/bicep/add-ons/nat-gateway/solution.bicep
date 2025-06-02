targetScope = 'subscription'

@description('Resource ID of the hub firewall.')
param hubFirewallResourceId string

@description('If Entra Domain Services is used, specify the subnet it is attached too, the NAT Gatewway will be required on that subnet directly.')
param entraDomainServicesSubnetId string = ''

@description('Zone for deployment. Use "" for no zone, or "1", "2", "3" for specific zones.  If no zone is specified, the NAT Gateway will be assigned a zone, however it will not be identifiable.')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param zone string = ''

@description('TCP idle timeout in minutes.')
@minValue(4)
@maxValue(120)
param tcpIdleTimeout int = 4

@description('The length of the public IP prefix to allocate for outbound connections. Must be /30 for two usable IPs.')
param publicIpPrefixLength int = 30

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

// Derive the resource group name from the firewall resource ID
var resourceGroupName = split(hubFirewallResourceId, '/')[4]

// Extract values from the firewall name (e.g., mlz-dev-va-hub-afw)
var firewallName = split(hubFirewallResourceId, '/')[8]
var identifier = split(firewallName, '-')[0]
var environmentAbbreviation = split(firewallName, '-')[1]
var networkName = split(firewallName, '-')[3]

// Get the firewall location
resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' existing = {
  name: firewallName
  scope: resourceGroup(resourceGroupName)
}
var location = firewall.location

// Call naming convention module to get nat gateway name
module namingConvention '../../modules/naming-convention.bicep' = {
  name: 'namingConvention-${deploymentNameSuffix}'
  scope: subscription()
  params: {
    delimiter: '-'
    environmentAbbreviation: environmentAbbreviation
    location: location
    networkName: networkName
    identifier: identifier // or use identifier if you want to match the firewall's
    stampIndex: ''
  }
}

// Get VNet and subnet info (including addressPrefix) from the firewall
module getNetworkInfo './modules/get-networkinfo.bicep' = {
  name: 'getNetworkInfo-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    hubFirewallResourceId: hubFirewallResourceId
  }
}

// Deploy the NAT Gateway and public IP prefix
module natGatewayModule './modules/nat-gateway.bicep' = {
  name: 'natGatewayDeploy-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    hubFirewallResourceId: hubFirewallResourceId
    location: location
    zone: zone
    natGatewayName: namingConvention.outputs.names.natGateway
    tcpIdleTimeout: tcpIdleTimeout
    publicIpPrefixLength: publicIpPrefixLength
    publicIpPrefixName: namingConvention.outputs.names.natGatewayPublicIPPrefix
  }
}

// Attach the NAT Gateway to the subnet
module attachNatGatewayToSubnet './modules/attach-natgw-to-subnet.bicep' = {
  name: 'attachNatGatewayToSubnet-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    vnetName: getNetworkInfo.outputs.vnetName
    subnetName: getNetworkInfo.outputs.subnetObj.name
    natGatewayId: natGatewayModule.outputs.natGatewayId
    addressPrefix: getNetworkInfo.outputs.subnetObj.properties.addressPrefix
    defaultOutboundAccess: getNetworkInfo.outputs.subnetObj.properties.defaultOutboundAccess // Ensure no default outbound access
    delegations: getNetworkInfo.outputs.subnetObj.properties.delegations
    serviceEndpoints: getNetworkInfo.outputs.subnetObj.properties.serviceEndpoints
    serviceEndpointPolicies: getNetworkInfo.outputs.subnetObj.properties.serviceEndpointPolicies
    privateEndpointNetworkPolicies: getNetworkInfo.outputs.subnetObj.properties.privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: getNetworkInfo.outputs.subnetObj.properties.privateLinkServiceNetworkPolicies
    networkSecurityGroupId: empty(getNetworkInfo.outputs.subnetObj.properties.networkSecurityGroup) ? '' : getNetworkInfo.outputs.subnetObj.properties.networkSecurityGroup.id
    routeTableId: empty(getNetworkInfo.outputs.subnetObj.properties.routeTable) ? '' : getNetworkInfo.outputs.subnetObj.properties.routeTable.id
  }
}

// If entraDomainServicesSubnetId is provided, attach NAT Gateway to that subnet as well
var attachToEntraSubnet = !empty(entraDomainServicesSubnetId)

var entraVnetName = attachToEntraSubnet ? split(entraDomainServicesSubnetId, '/')[8] : ''
var entraSubnetName = attachToEntraSubnet ? split(entraDomainServicesSubnetId, '/')[10] : ''

module getEntraSubnetInfo './modules/get-subnetinfo.bicep' = if (attachToEntraSubnet) {
  name: 'getEntraSubnetInfo'
  scope: resourceGroup(resourceGroupName)
  params: {
    vnetName: entraVnetName
    subnetName: entraSubnetName
  }
}

module attachNatGatewayToEntraSubnet './modules/attach-natgw-to-subnet.bicep' = if (attachToEntraSubnet) {
  name: 'attachNatGatewayToEntraSubnet-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    vnetName: entraVnetName
    subnetName: entraSubnetName
    natGatewayId: natGatewayModule.outputs.natGatewayId
    addressPrefix: getEntraSubnetInfo.outputs.subnet.properties.addressPrefix
    defaultOutboundAccess: getEntraSubnetInfo.outputs.subnet.properties.defaultOutboundAccess
    delegations: getEntraSubnetInfo.outputs.subnet.properties.delegations
    serviceEndpoints: getEntraSubnetInfo.outputs.subnet.properties.serviceEndpoints
    serviceEndpointPolicies: getEntraSubnetInfo.outputs.subnet.properties.serviceEndpointPolicies
    privateEndpointNetworkPolicies: getEntraSubnetInfo.outputs.subnet.properties.privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: getEntraSubnetInfo.outputs.subnet.properties.privateLinkServiceNetworkPolicies
    networkSecurityGroupId: empty(getEntraSubnetInfo.outputs.subnet.properties.networkSecurityGroup) ? '' : getEntraSubnetInfo.outputs.subnet.properties.networkSecurityGroup.id
    routeTableId: empty(getEntraSubnetInfo.outputs.subnet.properties.routeTable) ? '' : getEntraSubnetInfo.outputs.subnet.properties.routeTable.id
  }
}

