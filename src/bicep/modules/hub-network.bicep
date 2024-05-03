/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param bastionHostSubnetAddressPrefix string
param deployNetworkWatcher bool
param deployBastion bool
param dnsServers array
param enableProxy bool
param firewallClientIpConfigurationName string
param firewallClientPrivateIpAddress string
param firewallClientPublicIPAddressAvailabilityZones array
param firewallClientPublicIPAddressName string
param firewallClientPublicIPAddressSkuName string
param firewallClientPublicIpAllocationMethod string
param firewallClientSubnetAddressPrefix string
param firewallClientSubnetName string
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallIntrusionDetectionMode string
param firewallManagementIpConfigurationName string
param firewallManagementPublicIPAddressAvailabilityZones array
param firewallManagementPublicIPAddressName string
param firewallManagementPublicIPAddressSkuName string
param firewallManagementPublicIpAllocationMethod string
param firewallManagementSubnetAddressPrefix string
param firewallManagementSubnetName string
param firewallName string
param firewallPolicyName string
param firewallSkuTier string
param firewallSupernetIPAddress string
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallThreatIntelMode string
param location string
param mlzTags object
param networkSecurityGroupName string
param networkSecurityGroupRules array
param networkWatcherName string
param routeTableName string
param routeTableRouteAddressPrefix string = '0.0.0.0/0'
param routeTableRouteName string = 'default_route'
param routeTableRouteNextHopType string = 'VirtualAppliance'
param subnetAddressPrefix string
param subnetName string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param vNetDnsServers array

var subnets = union(subnetsCommon, subnetsBastion)
var subnetsBastion = deployBastion ? [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionHostSubnetAddressPrefix
    }
  }
] : []
var subnetsCommon = [
  {
    name: 'AzureFirewallSubnet'
    properties: {
      addressPrefix: firewallClientSubnetAddressPrefix
    }
  }
  {
    name: 'AzureFirewallManagementSubnet'
    properties: {
      addressPrefix: firewallManagementSubnetAddressPrefix
    }
  }
  {
    name: subnetName
    properties: {
      addressPrefix: subnetAddressPrefix
      networkSecurityGroup: {
        id: networkSecurityGroup.outputs.id
      }
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Disabled'
      routeTable: {
        id: routeTable.outputs.id
      }
    }
  }
]

module networkSecurityGroup '../modules/network-security-group.bicep' = {
  name: 'networkSecurityGroup'
  params: {
    location: location
    mlzTags: mlzTags
    name: networkSecurityGroupName
    securityRules: networkSecurityGroupRules
    tags: tags
  }
}

module routeTable '../modules/route-table.bicep' = {
  name: 'routeTable'
  params: {
    disableBgpRoutePropagation: false
    location: location
    mlzTags: mlzTags
    name: routeTableName
    routeAddressPrefix: routeTableRouteAddressPrefix
    routeName: routeTableRouteName
    routeNextHopIpAddress: firewallClientPrivateIpAddress
    routeNextHopType: routeTableRouteNextHopType
    tags: tags
  }
}

module networkWatcher '../modules/network-watcher.bicep' = if (deployNetworkWatcher) {
  name: 'networkWatcher'
  params: {
    location: location
    mlzTags: mlzTags
    name: networkWatcherName
    tags: tags
  }
}

module virtualNetwork '../modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    addressPrefix: virtualNetworkAddressPrefix
    location: location
    mlzTags: mlzTags
    name: virtualNetworkName
    subnets: subnets
    tags: tags
    vNetDnsServers: vNetDnsServers
    firewallSkuTier: firewallSkuTier
  }
  dependsOn: [
    networkWatcher
  ]
}

module firewallClientPublicIPAddress '../modules/public-ip-address.bicep' = {
  name: 'firewallClientPublicIPAddress'
  params: {
    availabilityZones: firewallClientPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: firewallClientPublicIPAddressName
    publicIpAllocationMethod: firewallClientPublicIpAllocationMethod
    skuName: firewallClientPublicIPAddressSkuName
    tags: tags
  }
}

module firewallManagementPublicIPAddress '../modules/public-ip-address.bicep' = {
  name: 'firewallManagementPublicIPAddress'
  params: {
    availabilityZones: firewallManagementPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: firewallManagementPublicIPAddressName
    publicIpAllocationMethod: firewallManagementPublicIpAllocationMethod
    skuName: firewallManagementPublicIPAddressSkuName
    tags: tags
  }
}

module firewall '../modules/firewall.bicep' = {
  name: 'firewall'
  params: {
    clientIpConfigurationName: firewallClientIpConfigurationName
    clientIpConfigurationPublicIPAddressResourceId: firewallClientPublicIPAddress.outputs.id
    clientIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/${firewallClientSubnetName}'
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallPolicyName: firewallPolicyName
    firewallSupernetIPAddress: firewallSupernetIPAddress
    intrusionDetectionMode: firewallIntrusionDetectionMode
    location: location
    managementIpConfigurationName: firewallManagementIpConfigurationName
    managementIpConfigurationPublicIPAddressResourceId: firewallManagementPublicIPAddress.outputs.id
    managementIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/${firewallManagementSubnetName}'
    mlzTags: mlzTags
    name: firewallName
    skuTier: firewallSkuTier
    tags: tags
    threatIntelMode: firewallThreatIntelMode
  }
}

output bastionHostSubnetResourceId string = deployBastion ? virtualNetwork.outputs.subnets[3].id : ''
output firewallName string = firewall.outputs.name
output firewallPrivateIPAddress string = firewall.outputs.privateIPAddress
output firewallResourceId string = firewall.outputs.resourceId
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string = networkSecurityGroup.outputs.id
output subnetAddressPrefix string = virtualNetwork.outputs.subnets[2].properties.addressPrefix
output subnetName string = virtualNetwork.outputs.subnets[2].name
output subnetResourceId string = virtualNetwork.outputs.subnets[2].id
output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id

