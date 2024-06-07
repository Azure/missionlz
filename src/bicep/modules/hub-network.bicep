/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param bastionHostSubnetAddressPrefix string
param azureGatewaySubnetAddressPrefix string
param deployNetworkWatcher bool
param deployBastion bool
param deployAzureGatewaySubnet bool
param dnsServers array
param enableProxy bool
param firewallClientPrivateIpAddress string
param firewallClientPublicIPAddressAvailabilityZones array
param firewallClientPublicIPAddressName string
param firewallClientSubnetAddressPrefix string
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallIntrusionDetectionMode string
param firewallManagementPublicIPAddressAvailabilityZones array
param firewallManagementPublicIPAddressName string
param firewallManagementSubnetAddressPrefix string
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
param subnetAddressPrefix string
param subnetName string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param vNetDnsServers array

var subnets = union([
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
], deployBastion ? [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionHostSubnetAddressPrefix
    }
  } 
] : [], deployAzureGatewaySubnet ? [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: azureGatewaySubnetAddressPrefix
    }
  }
] : [])

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
    routeNextHopIpAddress: firewallClientPrivateIpAddress
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
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
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
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
    tags: tags
  }
}

module firewall '../modules/firewall.bicep' = {
  name: 'firewall'
  params: {
    clientIpConfigurationPublicIPAddressResourceId: firewallClientPublicIPAddress.outputs.id
    clientIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallSubnet'
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallPolicyName: firewallPolicyName
    firewallSupernetIPAddress: firewallSupernetIPAddress
    intrusionDetectionMode: firewallIntrusionDetectionMode
    location: location
    managementIpConfigurationPublicIPAddressResourceId: firewallManagementPublicIPAddress.outputs.id
    managementIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallManagementSubnet'
    mlzTags: mlzTags
    name: firewallName
    skuTier: firewallSkuTier
    tags: tags
    threatIntelMode: firewallThreatIntelMode
  }
}

output bastionHostSubnetResourceId string = deployBastion ? virtualNetwork.outputs.subnets[3].id : ''
output dnsServers array = virtualNetwork.outputs.dnsServers
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

