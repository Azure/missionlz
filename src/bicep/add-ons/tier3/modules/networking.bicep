/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param additionalSubnets array
param deploymentNameSuffix string
param deployNetworkWatcher bool
param firewallSkuTier string
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
param workloadName string
param workloadShortName string

module spokeNetwork '../../../modules/spoke-network.bicep' = {
  name: 'spokeNetwork'
  params: {
    additionalSubnets: additionalSubnets
    deployNetworkWatcher: deployNetworkWatcher
    firewallSkuTier: firewallSkuTier
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
  name: 'deploy-vnet-peering-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    resourceGroupName: resourceGroupName
    spokeName: workloadName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    subscriptionId: subscriptionId
  }
}

module hubToWorkloadVirtualNetworkPeering '../../../modules/hub-network-peerings.bicep' = {
  name: 'deploy-vnet-peering-hub-${deploymentNameSuffix}'
  params: {
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId, '/')[8]
    resourceGroupName: split(hubVirtualNetworkResourceId, '/')[4]
    spokeName: workloadName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
    subscriptionId: split(hubVirtualNetworkResourceId, '/')[2]
  }
}

output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
