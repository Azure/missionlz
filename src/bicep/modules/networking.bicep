/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param bastionHostSubnetAddressPrefix string
param deployIdentity bool
param deploymentNameSuffix string
param deployNetworkWatcher bool
param deployBastion bool
param dnsServers array
param enableProxy bool
param firewallSettings object
param location string
param mlzTags object
param privateDnsZoneNames array
param resourceGroupNames array
param tiers array
param tags object

var hub = filter(tiers, tier => tier.name == 'hub')[0]
var hubResourceGroupName = filter(resourceGroupNames, name => contains(name, 'hub'))[0]
var spokes = filter(tiers, tier => tier.name != 'hub')
var spokeResourceGroupNames = filter(resourceGroupNames, name => !contains(name, 'hub'))

module hubNetwork 'hub-network.bicep' = {
  name: 'deploy-vnet-hub-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    deployNetworkWatcher: deployNetworkWatcher
    deployBastion: deployBastion
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallClientPrivateIpAddress: firewallSettings.clientPrivateIpAddress
    firewallClientPublicIPAddressAvailabilityZones: firewallSettings.clientPublicIPAddressAvailabilityZones
    firewallClientPublicIPAddressName: hub.namingConvention.azureFirewallClientPublicIPAddress
    firewallClientSubnetAddressPrefix: firewallSettings.clientSubnetAddressPrefix
    firewallIntrusionDetectionMode: firewallSettings.intrusionDetectionMode
    firewallManagementPublicIPAddressAvailabilityZones: firewallSettings.managementPublicIPAddressAvailabilityZones
    firewallManagementPublicIPAddressName: hub.namingConvention.azureFirewallManagementPublicIPAddress
    firewallManagementSubnetAddressPrefix: firewallSettings.managementSubnetAddressPrefix
    firewallName: hub.namingConvention.azureFirewall
    firewallPolicyName: hub.namingConvention.azureFirewallPolicy
    firewallSkuTier: firewallSettings.skuTier
    firewallSupernetIPAddress: firewallSettings.supernetIPAddress
    firewallThreatIntelMode: firewallSettings.threatIntelMode
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: hub.namingConvention.networkSecurityGroup
    networkSecurityGroupRules: hub.nsgRules
    networkWatcherName: hub.namingConvention.networkWatcher
    routeTableName: hub.namingConvention.routeTable
    subnetAddressPrefix: hub.subnetAddressPrefix
    subnetName: hub.namingConvention.subnet
    tags: tags
    virtualNetworkAddressPrefix: hub.vnetAddressPrefix
    virtualNetworkName: hub.namingConvention.virtualNetwork
    vNetDnsServers: firewallSettings.skuTier == 'Premium' || firewallSettings.skuTier == 'Standard' ? [
      firewallSettings.clientPrivateIpAddress
    ] : []
  }
}

module spokeNetworks 'spoke-network.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-${spoke.name}-${deploymentNameSuffix}'
  params: {
    deployNetworkWatcher: deployNetworkWatcher && spoke.deployUniqueResources
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: spoke.namingConvention.networkSecurityGroup
    networkSecurityGroupRules: spoke.nsgRules
    networkWatcherName: spoke.namingConvention.networkWatcher
    resourceGroupName: spokeResourceGroupNames[i]
    routeTableName: spoke.namingConvention.routeTable
    routeTableRouteNextHopIpAddress: firewallSettings.clientPrivateIpAddress
    subnetAddressPrefix: spoke.subnetAddressPrefix
    subnetName: spoke.namingConvention.subnet
    subscriptionId: spoke.subscriptionId
    tags: tags
    virtualNetworkAddressPrefix: spoke.vnetAddressPrefix
    virtualNetworkName: spoke.namingConvention.virtualNetwork
    vNetDnsServers: hubNetwork.outputs.dnsServers
  }
}]

// VIRTUAL NETWORK PEERINGS

module hubVirtualNetworkPeerings 'hub-network-peerings.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-hub-${i}-${deploymentNameSuffix}'
  params: {
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    resourceGroupName: hubResourceGroupName
    spokeName: spoke.name
    spokeVirtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
    subscriptionId: hub.subscriptionId
  }
}]

module spokeVirtualNetworkPeerings 'spoke-network-peering.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-${spoke.name}-${deploymentNameSuffix}'
  params: {
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
    resourceGroupName: spokeResourceGroupNames[i]
    spokeName: spoke.name
    spokeVirtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
    subscriptionId: spoke.subscriptionId
  }
}]

// PRIVATE DNS

module privateDnsZones 'private-dns.bicep' = {
  name: 'deploy-private-dns-zones-${deploymentNameSuffix}'
  scope: resourceGroup(hub.subscriptionId, hubResourceGroupName)
  params: {
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
    identityVirtualNetworkResourceId: deployIdentity ? spokeNetworks[2].outputs.virtualNetworkResourceId : ''
    mlzTags: mlzTags
    privateDnsZoneNames: privateDnsZoneNames
    tags: tags
  }
  dependsOn: [
    spokeNetworks
  ]
}

output azureFirewallResourceId string = hubNetwork.outputs.firewallResourceId
output bastionHostSubnetResourceId string = hubNetwork.outputs.bastionHostSubnetResourceId
output sharedServicesSubnetResourceId string = spokeNetworks[1].outputs.subnetResourceId
output hubNetworkSecurityGroupResourceId string = hubNetwork.outputs.networkSecurityGroupResourceId
output hubSubnetResourceId string = hubNetwork.outputs.subnetResourceId
output hubVirtualNetworkResourceId string = hubNetwork.outputs.virtualNetworkResourceId
output identitySubnetResourceId string = deployIdentity ? spokeNetworks[2].outputs.subnetResourceId : ''
output operationsSubnetResourceId string = spokeNetworks[0].outputs.subnetResourceId
output privateDnsZoneResourceIds object = privateDnsZones.outputs.privateDnsZoneResourceIds
