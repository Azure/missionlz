targetScope = 'subscription'

@description('Optional: Provide your own Firewall Policy rule collection groups. When non-empty, these override the default VGW-OnPrem group built by this template.')
param customFirewallRuleCollectionGroups array = []

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

@allowed([
  'dev'
  'prod'
  'test'
])
@description('[dev/prod/test] The abbreviation for the target environment.')
param environmentAbbreviation string = 'dev'

@description('The resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string

@minLength(1)
@maxLength(5)
@description('1-5 alphanumeric characters without whitespace, used to name resources and generate uniqueness for resources within your subscription. Ideally, the value should represent an organization, department, or business unit.')
param identifier string

@description('Address prefixes of the Local Network which will be routable through the VPN Gateway')
param localAddressPrefixes array

@description('IP Address of the Local Network Gateway, must be a public IP address reachable from the MLZ network')
param localGatewayIpAddress string

@description('Resource ID of the Operations Log Analytics Workspace where diagnostics should be sent.')
param operationsLogAnalyticsWorkspaceResourceId string

@description('The shared key to use for the VPN connection. If not provided, a random GUID will be generated.')
@secure()
param sharedKey string = newGuid()

@description('The SKU of the virtual network gateway.')
@allowed(['VpnGw2', 'VpnGw3', 'VpnGw4', 'VpnGw5'])
param virtualNetworkGatewaySku string = 'VpnGw2'

@description('List of peered networks that should use the VPN Gateway once configured.')
param virtualNetworkResourceIdList array

@description('Optional configuration for VPN NAT (Network Address Translation). Defines rules and their association with the connection.')
param natConfiguration object = {
  natRules: []
  ingressNatRuleNames: []
  egressNatRuleNames: []
}

@description('Default CIDR to use when creating the GatewaySubnet if it does not exist.')
var defaultGatewaySubnetPrefix = '10.0.129.192/26'

var azureFirewallIpConfigurationResourceId = filter(virtualNetwork.properties.subnets, subnet => subnet.name == 'AzureFirewallSubnet')[0].properties.ipConfigurations[0].id

var azureFirewallResourceId = resourceId(split(azureFirewallIpConfigurationResourceId, '/')[2], split(azureFirewallIpConfigurationResourceId, '/')[4], 'Microsoft.Network/azureFirewalls', split(azureFirewallIpConfigurationResourceId, '/')[8])
var hubResourceGroupName = split(hubVirtualNetworkResourceId, '/')[4]
var hubVirtualNetworkName = split(hubVirtualNetworkResourceId, '/')[8]
var location = virtualNetwork.location

// Remove start-time var causing error; pass VNet list down and let module derive
// Precompute spoke address prefixes to avoid runtime copy in nested deployment params
// var spokeAddressPrefixSets = [for (vnetId, i) in virtualNetworkResourceIdList: retrieveVnetInfo[i].outputs.vnetAddressSpace]

// Determine existing GatewaySubnet prefix (if discovered) or fall back to default
// Discover GatewaySubnet prefix directly from the hub VNet's subnets (safe even if missing)
var gatewaySubnetMatches = filter(virtualNetwork.properties.subnets, s => s.name == 'GatewaySubnet')
var discoveredGatewaySubnetPrefix = length(gatewaySubnetMatches) > 0 ? gatewaySubnetMatches[0].properties.addressPrefix : ''
var effectiveGatewaySubnetPrefix = !empty(discoveredGatewaySubnetPrefix) ? discoveredGatewaySubnetPrefix : defaultGatewaySubnetPrefix

// No explicit Local Network Gateway parameters; on-prem specific rules are omitted in this minimal-parameter variant

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(hubVirtualNetworkResourceId, '/')[8]
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
}

module logic '../../modules/logic.bicep' = {
  name: 'logic-${deploymentNameSuffix}'
  params: {
    delimiter: '-'
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    identifier: identifier
    location: location
    networks: [
      {
        name: 'hub'
        shortName: 'hub'
        subscriptionId: subscription().subscriptionId
      }
    ]
  }
}

module firewallPolicy 'modules/firewall-policy.bicep' = {
  name: 'firewallPolicy-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    azureFirewallResourceId: azureFirewallResourceId
  }
}

module collectSpokeAddresses 'modules/collect-spoke-addresses.bicep' = {
  name: 'collectSpokeAddresses-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    virtualNetworkResourceIdList: virtualNetworkResourceIdList
  }
}

module firewallRules 'modules/firewall-rules-vgw.bicep' = {
  name: 'deploy-vgw-firewall-rules-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    firewallPolicyName: firewallPolicy.outputs.name
    hubAddressPrefixes: virtualNetwork.properties.addressSpace.addressPrefixes
    spokeAddressPrefixSets: collectSpokeAddresses.outputs.spokeAddressPrefixSets
    localAddressPrefixes: localAddressPrefixes
    firewallRuleCollectionGroups: customFirewallRuleCollectionGroups
  // hub always included now; parameter removed
  }
}

// No validation resource needed since shared key / certificate inputs were removed

// calling Virtual Network Gateway Module
module virtualNetworkGateway 'modules/virtual-network-gateway.bicep' = {
  name: 'vpnGateway-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    delimiter: logic.outputs.delimiter
    location: location
    publicIpAddressName: logic.outputs.tiers[0].namingConvention.virtualNetworkGatewayPublicIpAddress
    resourceAbbreviations: logic.outputs.resourceAbbreviations
    tokens: logic.outputs.tokens
    virtualNetworkGatewayName: replace(logic.outputs.tiers[0].namingConvention.virtualNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')
    virtualNetworkGatewaySku: virtualNetworkGatewaySku
    virtualNetworkName: hubVirtualNetworkName
    natRules: natConfiguration.natRules
  }
  dependsOn: [
    ensureGatewaySubnet
  ]
}

// Configure diagnostics to Operations Log Analytics workspace
module vpnGatewayDiagnostics 'modules/virtual-network-gateway-diagnostics.bicep' = {
  name: 'vpnGateway-diagnostics-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    logAnalyticsWorkspaceResourceId: operationsLogAnalyticsWorkspaceResourceId
    virtualNetworkGatewayName: replace(logic.outputs.tiers[0].namingConvention.virtualNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')
  }
  dependsOn: [
    virtualNetworkGateway
  ]
}

// Create Local Network Gateway based on provided on-prem configuration
module localNetworkGateway 'modules/local-network-gateway.bicep' = {
  name: 'localNetworkGateway-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    addressPrefixes: localAddressPrefixes
    gatewayIpAddress: localGatewayIpAddress
    localNetworkGatewayName: replace(logic.outputs.tiers[0].namingConvention.localNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')
    vgwlocation: location
  }
}

// Create VPN Connection using the shared key
module vpnConnection 'modules/virtual-network-gateway-connection.bicep' = {
  name: 'vpnConnection-${deploymentNameSuffix}'
  scope: resourceGroup(hubResourceGroupName)
  params: {
    keyVaultCertificateUri: ''
    localNetworkGatewayName: replace(logic.outputs.tiers[0].namingConvention.localNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')
    sharedKey: sharedKey
    vgwlocation: location
    vpnConnectionName: '${replace(logic.outputs.tiers[0].namingConvention.virtualNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')}-to-${replace(logic.outputs.tiers[0].namingConvention.localNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')}'
    vpnGatewayName: replace(logic.outputs.tiers[0].namingConvention.virtualNetworkGateway, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')
    vpnGatewayResourceGroupName: hubResourceGroupName
    ingressNatRuleIds: [for name in natConfiguration.ingressNatRuleNames: '${virtualNetworkGateway.outputs.virtualNetworkGatewayId}/natRules/${name}']
    egressNatRuleIds: [for name in natConfiguration.egressNatRuleNames: '${virtualNetworkGateway.outputs.virtualNetworkGatewayId}/natRules/${name}']
  }
  dependsOn: [
    localNetworkGateway
  ]
}

// Loop through the vnetResourceIdList and to retrieve the peerings for each VNet
module retrieveVnetInfo 'modules/virtual-network-info.bicep' = [for (vnetId, i) in virtualNetworkResourceIdList: {
  name: 'retrieveVnetPeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: vnetId
  }
}]

// Get the hub virtual network peerings
module retrieveHubVnetInfo 'modules/virtual-network-info.bicep' = {
  name: 'retrieveHubVnetPeerings-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
  }
}

// Retrieve firewall private IP and (optionally) GatewaySubnet prefix without peering deps
module firewallInfo 'modules/firewall-info.bicep' = {
  name: 'firewallInfo-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    azureFirewallResourceId: azureFirewallResourceId
  }
}
// Ensure the GatewaySubnet exists (or is configured) before associating the dedicated vgw route table
module ensureGatewaySubnet 'modules/create-gateway-subnet.bicep' = {
  name: 'ensureGatewaySubnet-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
    subnetName: 'GatewaySubnet'
    subnetAddressPrefix: effectiveGatewaySubnetPrefix
  }
}

// Call update the Hub peerings first to enable spokes to use the VPN Gateway, if not done first, spokes will fail their update
module updateHubPeerings 'modules/virtual-network-peerings.bicep' = {
  name: 'updateHubPeerings-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: retrieveHubVnetInfo.outputs.peeringsData.vnetResourceId
    peeringsList: retrieveHubVnetInfo.outputs.peeringsData.peeringsList
  }
  dependsOn: [
    virtualNetworkGateway
  ]
}


// Update the peerings for each spoke VNet to use the VPN Gateway
module updatePeerings 'modules/virtual-network-peerings.bicep' = [for (vnetId, i) in virtualNetworkResourceIdList: {
  name: 'updatePeerings-${deploymentNameSuffix}-${i}'
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
  params: {
    vnetResourceId: retrieveVnetInfo[i].outputs.peeringsData.vnetResourceId
    peeringsList: retrieveVnetInfo[i].outputs.peeringsData.peeringsList
  }
  dependsOn: [
    updateHubPeerings
    virtualNetworkGateway
  ]
}]

// Always create the dedicated route table for forced tunneling via the firewall
module createRouteTable 'modules/route-table.bicep' = {
  name: 'createVgwRouteTable-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    routeTableName: replace(logic.outputs.tiers[0].namingConvention.routeTable, logic.outputs.tokens.purpose, 'vgw')
    // Disable BGP propagation (no BGP usage; static enforcement)
    disableBgpRoutePropagation: true
  }
}

// Add static routes for each spoke via firewall (forced tunneling)
module createRoutes 'modules/routes.bicep' = [for (vnetResourceId, i) in virtualNetworkResourceIdList: {
  name: 'createRoute-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    addressSpace: retrieveVnetInfo[i].outputs.vnetAddressSpace
    nextHopIpAddress: firewallInfo.outputs.firewallPrivateIp
    nextHopType: 'VirtualAppliance'
    routeName: 'route-${i}'
    routeTableName: replace(logic.outputs.tiers[0].namingConvention.routeTable, logic.outputs.tokens.purpose, 'vgw')
  }
  dependsOn: [
    createRouteTable
  ]
}]

// Add Hub VNet address prefixes to the VGW route table to steer Hub CIDRs through the firewall
module createHubCidrRoutes 'modules/routes.bicep' = {
  name: 'createHubCidrRoutes-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    routeTableName: replace(logic.outputs.tiers[0].namingConvention.routeTable, logic.outputs.tokens.purpose, 'vgw')
    addressSpace: virtualNetwork.properties.addressSpace.addressPrefixes
    routeName: 'route-hub'
    nextHopType: 'VirtualAppliance'
  nextHopIpAddress: firewallInfo.outputs.firewallPrivateIp
  }
  dependsOn: [
    createRouteTable
  ]
}

// Add on-prem prefixes to the hub workload route table so hub workloads egress to the firewall
// Add on-prem prefixes to the hub workload route table so hub workloads egress to the firewall
module createHubRouteOverrides 'modules/routes.bicep' = {
  name: 'createHubRouteOverrides-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    addressSpace: localAddressPrefixes
    nextHopIpAddress: firewallInfo.outputs.firewallPrivateIp
    nextHopType: 'VirtualAppliance'
    routeName: 'route-onprem-override'
    routeTableName: replace(logic.outputs.tiers[0].namingConvention.routeTable, '${logic.outputs.delimiter}${logic.outputs.tokens.purpose}', '')
  }
}

// Associate the vgw route table to GatewaySubnet
module associateRouteTable 'modules/associate-route-table.bicep' = {
  name: 'associateRouteTable-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    vnetResourceId: hubVirtualNetworkResourceId
    // safe: module only exists in same condition
  // Safely pass the route table id (module exists only under same condition)
  routeTableResourceId: createRouteTable.outputs.routeTableId
    subnetName: 'GatewaySubnet'
    subnetAddressPrefix: effectiveGatewaySubnetPrefix
  }
  dependsOn: [
    ensureGatewaySubnet
    virtualNetworkGateway
  ]
}

// (Removed routingMode output; forced tunneling is mandatory now)

