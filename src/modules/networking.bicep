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

var hubSubscriptionId = filter(networks, network => network.name == 'hub')[0].subscriptionId
var spokes = filter(networks, network => network.name != 'hub')

module logic 'logic.bicep' = {
  name: 'get-logic-${deploymentNameSuffix}'
  params: {
    delimiter: '-'
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
    purpose: 'network'
    tiers: logic.outputs.tiers
    tags: tags
    tokens: logic.outputs.tokens
  }
}

module hubNetwork 'hub-network.bicep' = {
  name: 'deploy-vnet-hub-${deploymentNameSuffix}'
  params: {
    azureGatewaySubnetAddressPrefix: azureGatewaySubnetAddressPrefix
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    delimiter: logic.outputs.delimiter
    deployAzureGatewaySubnet: deployAzureGatewaySubnet
    deployBastion: deployBastion
    deploymentNameSuffix: deploymentNameSuffix
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallClientPrivateIpAddress: firewallSettings.clientPrivateIpAddress
    firewallClientPublicIPAddressAvailabilityZones: firewallSettings.clientPublicIPAddressAvailabilityZones
    firewallClientSubnetAddressPrefix: firewallSettings.clientSubnetAddressPrefix
    firewallCustomPipCount: firewallSettings.customPipCount
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
    tokens: logic.outputs.tokens
    vNetDnsServers: [
      firewallSettings.clientPrivateIpAddress
    ]
  }
}

module spokeNetworks 'spoke-network.bicep' = [for (spoke, i) in spokes: {
  name: 'deploy-vnet-${spoke.name}-${deploymentNameSuffix}'
  params: {
    delimiter: logic.outputs.delimiter
    location: location
    mlzTags: logic.outputs.mlzTags
    resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, spoke.name))[0]
    routeTableRouteNextHopIpAddress: firewallSettings.clientPrivateIpAddress
    tags: tags
    tier: filter(logic.outputs.tiers, tier => tier.name == spoke.name)[0]
    tokens: logic.outputs.tokens
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

// PRIVATE DNS ZONES

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
output bastionHostSubnetResourceId string = hubNetwork.outputs.bastionHostSubnetResourceId
output delimiter string = logic.outputs.delimiter
output firewallPolicyResourceId string = hubNetwork.outputs.firewallPolicyResourceId
output hubVirtualNetworkResourceId string = hubNetwork.outputs.virtualNetworkResourceId
output locationProperties object = logic.outputs.locationProperties
output mlzTags object = logic.outputs.mlzTags
output privateDnsZoneResourceIds object = {
  agentSvc: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'privatelink.agentsvc'))[0]
  blob: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'blob'))[0]
  file: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'file'))[0]
  keyVault: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'vaultcore'))[0]
  monitor: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'monitor'))[0]
  ods: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'ods.opinsights'))[0]
  oms: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'oms.opinsights'))[0]
  queue: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'queue'))[0]
  table: filter(privateDnsZones.outputs.privateDnsZoneResourceIds, id => contains(id, 'table'))[0]
}
output resourceAbbreviations object = logic.outputs.resourceAbbreviations
output sharedServicesSubnetResourceId string = spokeNetworks[1].outputs.networkSecurityGroupResourceId 
output tiers array = [for (network, i) in networks: {
  name: network.name
  namingConvention: logic.outputs.tiers[i].namingConvention
  networkSecurityGroupResourceId: union([
    hubNetwork.outputs.networkSecurityGroupResourceId
    spokeNetworks[0].outputs.networkSecurityGroupResourceId // Operations
    spokeNetworks[1].outputs.networkSecurityGroupResourceId // Shared Services
  ], deployIdentity ? [
    spokeNetworks[2].outputs.networkSecurityGroupResourceId // Identity
  ] : [])[i]
  nsgDiagLogs: network.nsgDiagLogs
  resourceGroupName: filter(resourceGroups.outputs.names, name => contains(name, network.name))[0]
  shortName: network.shortName
  subnetResourceId: union([
    hubNetwork.outputs.subnetResourceId
    spokeNetworks[0].outputs.subnets[0].id // Operations
    spokeNetworks[1].outputs.subnets[0].id // Shared Services
  ], deployIdentity ? [
    spokeNetworks[2].outputs.subnets[0].id // Identity
  ] : [])[i]
  subscriptionId: network.subscriptionId
  vnetDiagLogs: network.vnetDiagLogs
  vnetDiagMetrics: network.vnetDiagMetrics
}]
output tokens object = logic.outputs.tokens
