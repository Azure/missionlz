/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param additionalSubnets array
param deploymentNameSuffix string
param deployNetworkWatcher bool
param hubVirtualNetworkResourceId string
param location string
param mlzTags object
param networkSecurityGroupName string
param networkSecurityGroupRules array
param networkWatcherName string
param resourceGroupName string
param routeTableName string
param routeTableRouteNextHopIpAddress string
param subnetAddressPrefix string
param subnetName string
param subscriptionId string
param tags object
param vNetDnsServers array
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param workloadShortName string

module spokeNetwork '../../../modules/spoke-network.bicep' = {
  name: 'deploy-spoke-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    additionalSubnets: additionalSubnets
    deployNetworkWatcher: deployNetworkWatcher
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: networkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherName: networkWatcherName
    resourceGroupName: resourceGroupName
    routeTableName: routeTableName
    routeTableRouteNextHopIpAddress: routeTableRouteNextHopIpAddress
    subnetAddressPrefix: subnetAddressPrefix
    subnetName: subnetName
    subscriptionId: subscriptionId
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkName: virtualNetworkName
    vNetDnsServers: vNetDnsServers
  }
}

module workloadVirtualNetworkPeerings '../../../modules/spoke-network-peering.bicep' = {
  name: 'deploy-spoke-peering-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    resourceGroupName: resourceGroupName
    spokeShortName: workloadShortName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    subscriptionId: subscriptionId
  }
}

module hubToWorkloadVirtualNetworkPeering '../../../modules/hub-network-peerings.bicep' = {
  name: 'deploy-hub-peering-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId, '/')[8]
    resourceGroupName: split(hubVirtualNetworkResourceId, '/')[4]
    spokeShortName: workloadShortName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
    subscriptionId: split(hubVirtualNetworkResourceId, '/')[2]
  }
}

output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output subnets array = spokeNetwork.outputs.subnets
output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
