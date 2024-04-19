/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param deployNetworkWatcher bool
param firewallSkuTier string
param location string
param mlzTags object
param networkSecurityGroupName string
param networkSecurityGroupRules array
param networkWatcherName string
param routeTableName string
param routeTableRouteName string = 'default_route'
param routeTableRouteAddressPrefix string = '0.0.0.0/0'
param routeTableRouteNextHopIpAddress string
param routeTableRouteNextHopType string = 'VirtualAppliance'
param subnetAddressPrefix string
param subnetName string
param subnetPrivateEndpointNetworkPolicies string
param subnetPrivateLinkServiceNetworkPolicies string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param vNetDnsServers array

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
    disableBgpRoutePropagation: true
    location: location
    mlzTags: mlzTags
    name: routeTableName
    routeAddressPrefix: routeTableRouteAddressPrefix
    routeName: routeTableRouteName
    routeNextHopIpAddress: routeTableRouteNextHopIpAddress
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
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.outputs.id
          }
          routeTable: {
            id: routeTable.outputs.id
          }
          privateEndpointNetworkPolicies: subnetPrivateEndpointNetworkPolicies
          privateLinkServiceNetworkPolicies: subnetPrivateLinkServiceNetworkPolicies
        }
      }
    ]
    tags: tags
    vNetDnsServers: vNetDnsServers
    firewallSkuTier: firewallSkuTier
  }
  dependsOn: [
    networkWatcher
  ]
}

output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
output virtualNetworkAddressPrefix string = virtualNetwork.outputs.addressPrefix
output subnetName string = virtualNetwork.outputs.subnets[0].name
output subnetAddressPrefix string = virtualNetwork.outputs.subnets[0].properties.addressPrefix
output subnetResourceId string = virtualNetwork.outputs.subnets[0].id
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  networkSecurityGroup.outputs.id
