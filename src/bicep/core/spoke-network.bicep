/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/
param firewallSkuTier string
param location string
param networkSecurityGroupName string
param networkSecurityGroupRules array
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
    name: networkSecurityGroupName
    securityRules: networkSecurityGroupRules
    tags: tags
  }
}

module routeTable '../modules/route-table.bicep' = {
  name: 'routeTable'
  params: {
    location: location
    name: routeTableName
    routeAddressPrefix: routeTableRouteAddressPrefix
    routeName: routeTableRouteName
    routeNextHopIpAddress: routeTableRouteNextHopIpAddress
    routeNextHopType: routeTableRouteNextHopType
    tags: tags
  }
}

module virtualNetwork '../modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    addressPrefix: virtualNetworkAddressPrefix
    location: location
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
}

output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
output virtualNetworkAddressPrefix string = virtualNetwork.outputs.addressPrefix
output subnetName string = virtualNetwork.outputs.subnets[0].name
output subnetAddressPrefix string = virtualNetwork.outputs.subnets[0].properties.addressPrefix
output subnetResourceId string = virtualNetwork.outputs.subnets[0].id
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  networkSecurityGroup.outputs.id
