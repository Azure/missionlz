/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

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
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    deployNetworkWatcher: deployNetworkWatcher
    firewallSkuTier: firewallSkuTier
    location: location
    mlzTags: mlzTags
    networkSecurityGroupName: networkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherName: networkWatcherName
    routeTableName: routeTableName
    routeTableRouteNextHopIpAddress: routeTableRouteNextHopIpAddress
    subnetAddressPrefix: subnetAddressPrefix
    subnetName: subnetName
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkName: virtualNetworkName
    vNetDnsServers: vNetDnsServers
  }
}

module workloadVirtualNetworkPeerings '../../../modules/spoke-network-peering.bicep' = {
  name: 'deploy-vnet-peering-${workloadShortName}-${deploymentNameSuffix}'
  params: {
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId, '/')[8]
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    spokeName: workloadName
    spokeResourceGroupName: resourceGroupName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
  }
}

module hubToWorkloadVirtualNetworkPeering '../../../modules/hub-network-peerings.bicep' = {
  name: 'deploy-vnet-peering-hub-${deploymentNameSuffix}'
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
  params: {
    hubVirtualNetworkName: split(hubVirtualNetworkResourceId, '/')[8]
    spokes: [
      {
        type: workloadName
        virtualNetworkName: virtualNetworkName
        virtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
      }
    ]
  }
}

output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
