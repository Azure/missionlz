/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param azureGatewaySubnetAddressPrefix string
param bastionHostSubnetAddressPrefix string
param deployAzureGatewaySubnet bool
param deployBastion bool
param deployIdentity bool
param deploymentNameSuffix string
param dnsServers array
param enableProxy bool
param environmentAbbreviation string
param firewallRuleCollectionGroups array
param firewallSettings object
param identifier string
param location string
param networks array
param tags object

// var hub = filter(tiers, tier => tier.name == 'hub')[0]
// var hubResourceGroupName = filter(resourceGroupNames, name => contains(name, 'hub'))[0]
var hubSubscriptionId = filter(networks, network => network.name == 'hub')[0].subscriptionId
var spokes = filter(networks, network => network.name != 'hub')
// var spokeResourceGroupNames = filter(resourceGroupNames, name => !contains(name, 'hub'))

module logic 'logic.bicep' = {
  name: 'get-logic-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    identifier: identifier
    location: location
    networks: networks
  }
}

module resourceGroups 'resource-groups.bicep' = {
  name: 'deploy-resource-groups-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    location: location
    mlzTags: logic.outputs.mlzTags
    tiers: logic.outputs.tiers
    tags: tags
  }
}

module hubNetwork 'hub-network.bicep' = {
  name: 'deploy-vnet-hub-${deploymentNameSuffix}'
  params: {
    azureGatewaySubnetAddressPrefix: azureGatewaySubnetAddressPrefix
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    deployAzureGatewaySubnet: deployAzureGatewaySubnet
    deployBastion: deployBastion
    deploymentNameSuffix: deploymentNameSuffix
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallClientPrivateIpAddress: firewallSettings.clientPrivateIpAddress
    firewallClientPublicIPAddressAvailabilityZones: firewallSettings.clientPublicIPAddressAvailabilityZones
    firewallClientSubnetAddressPrefix: firewallSettings.clientSubnetAddressPrefix
    firewallIntrusionDetectionMode: firewallSettings.intrusionDetectionMode
    firewallManagementPublicIPAddressAvailabilityZones: firewallSettings.managementPublicIPAddressAvailabilityZones
    firewallManagementSubnetAddressPrefix: firewallSettings.managementSubnetAddressPrefix
    firewallSkuTier: firewallSettings.skuTier
    firewallThreatIntelMode: firewallSettings.threatIntelMode
    firewallRuleCollectionGroups: firewallRuleCollectionGroups
    location: location
    mlzTags: logic.outputs.mlzTags 
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, 'hub'))[0]
    subscriptionId: hubSubscriptionId
    tags: tags
    tier: filter(logic.outputs.tiers, tier => tier.name == 'hub')[0]
    vNetDnsServers: [
      firewallSettings.clientPrivateIpAddress
    ]
  }
}

module spokeNetworks 'spoke-network.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-${spoke.name}-${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: logic.outputs.mlzTags
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, spoke.name))[0]
    routeTableRouteNextHopIpAddress: firewallSettings.clientPrivateIpAddress
    tags: tags
    tier: filter(logic.outputs.tiers, tier => tier.name == spoke.name)[0]
    vNetDnsServers: hubNetwork.outputs.dnsServers
  }
}]

// VIRTUAL NETWORK PEERINGS

module hubVirtualNetworkPeerings 'hub-network-peerings.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-hub-${i}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, 'hub'))[0]
    spokeShortName: spoke.shortName
    spokeVirtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
    subscriptionId: hubSubscriptionId
  }
}]

module spokeVirtualNetworkPeerings 'spoke-network-peering.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-${spoke.name}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, spoke.name))[0]
    spokeShortName: spoke.shortName
    spokeVirtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
    subscriptionId: spoke.subscriptionId
  }
}]

// PRIVATE DNS

module privateDnsZones 'private-dns-zones.bicep' = {
  name: 'deploy-private-dns-zones-${deploymentNameSuffix}'
  params: {
    deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
    identityVirtualNetworkResourceId: deployIdentity ? spokeNetworks[2].outputs.virtualNetworkResourceId : ''
    mlzTags: logic.outputs.mlzTags
    privateDnsZoneNames: logic.outputs.privateDnsZones
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, 'hub'))[0]
    subscriptionId: hubSubscriptionId
    tags: tags
  }
  dependsOn: [
    spokeNetworks
  ]
}

output azureFirewallResourceId string = hubNetwork.outputs.firewallResourceId
output hubVirtualNetworkResourceId string = hubNetwork.outputs.virtualNetworkResourceId
output bastionHostSubnetResourceId string = hubNetwork.outputs.bastionHostSubnetResourceId
output privateDnsZoneResourceIds object = privateDnsZones.outputs.privateDnsZoneResourceIds
output sharedServicesSubnetResourceId string = spokeNetworks[1].outputs.networkSecurityGroupResourceId 
output tiers array = [for (network, i) in networks: {
  delimiter: logic.outputs.tiers[i].delimiter
  locationProperties: logic.outputs.tiers[0].locationProperties
  mlzTags: logic.outputs.mlzTags
  name: network.name
  namingConvention: logic.outputs.tiers[i].namingConvention
  networkSecurityGroupResourceId: [
    hubNetwork.outputs.networkSecurityGroupResourceId
    spokeNetworks[0].outputs.networkSecurityGroupResourceId // Operations
    spokeNetworks[1].outputs.networkSecurityGroupResourceId // Shared Services
    spokeNetworks[2].outputs.networkSecurityGroupResourceId // Identity
  ][i]
  resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, network.name))[0]
  shortName: network.shortName
  subnetResourceId: [
    hubNetwork.outputs.subnetResourceId
    spokeNetworks[0].outputs.subnets[0].id // Operations
    spokeNetworks[1].outputs.subnets[0].id // Shared Services
    spokeNetworks[2].outputs.subnets[0].id // Identity
  ][i]
  subscriptionId: network.subscriptionId
}]
