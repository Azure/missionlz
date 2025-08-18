/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param additionalSubnets array
param deploymentIndex string
param deploymentNameSuffix string
param environmentAbbreviation string
param hubVirtualNetworkResourceId string
param identifier string
param location string
param network object
param routeTableRouteNextHopIpAddress string
param stampIndex string
param subnetName string
param tags object
param vNetDnsServers array

module logic '../../../modules/logic.bicep' = {
  name: 'get-logic-${network.shortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    delimiter: '-'
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    identifier: identifier
    location: location
    networks: [network]
    stampIndex: stampIndex
  }
}

module rg '../../../modules/resource-group.bicep' = {
  name: 'deploy-rg-${network.shortName}-${deploymentIndex}${deploymentNameSuffix}'
  params: {
    location: location
    mlzTags: logic.outputs.mlzTags
    name: '${logic.outputs.tiers[0].namingConvention.resourceGroup}${logic.outputs.delimiter}network'
    tags: tags
  }
}

module spokeNetwork '../../../modules/spoke-network.bicep' = {
  name: 'deploy-spoke-${network.shortName}-${deploymentNameSuffix}'
  params: {
    additionalSubnets: additionalSubnets
    customSubnetName: subnetName
    location: location
    mlzTags: logic.outputs.mlzTags
    resourceGroupName: rg.outputs.name
    routeTableRouteNextHopIpAddress: routeTableRouteNextHopIpAddress
    tags: tags
    tier: logic.outputs.tiers[0]
    vNetDnsServers: vNetDnsServers
  }
}

module workloadVirtualNetworkPeerings '../../../modules/spoke-network-peering.bicep' = {
  name: 'deploy-spoke-peering-${network.shortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    resourceGroupName: rg.outputs.name
    spokeShortName: network.shortName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    subscriptionId: network.subscriptionId
  }
}

module hubToWorkloadVirtualNetworkPeering '../../../modules/hub-network-peerings.bicep' = {
  name: 'deploy-hub-peering-${network.shortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId, '/')[8]
    resourceGroupName: split(hubVirtualNetworkResourceId, '/')[4]
    spokeShortName: network.shortName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
    subscriptionId: split(hubVirtualNetworkResourceId, '/')[2]
  }
}

output delimiter string = logic.outputs.delimiter
output locationProperties object = logic.outputs.locationProperties
output mlzTags object = logic.outputs.mlzTags
output privateDnsZones array = logic.outputs.privateDnsZones
output resourceAbbreviations object = logic.outputs.resourceAbbreviations
output tier object = {  
  name: network.name
  namingConvention: logic.outputs.tiers[0].namingConvention
  networkSecurityGroupResourceId: spokeNetwork.outputs.networkSecurityGroupResourceId
  resourceGroupName: rg.outputs.name
  shortName: network.shortName
  subnetResourceId: spokeNetwork.outputs.subnets[0].id
  subnets: spokeNetwork.outputs.subnets
  subscriptionId: network.subscriptionId
}
output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
