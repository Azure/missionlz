/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param additionalSubnets array = []
param location string
param mlzTags object
param networkSecurityGroupName string
param networkSecurityGroupRules array
param resourceGroupName string
param routeTableName string
param routeTableRouteNextHopIpAddress string
param subnetAddressPrefix string
param subnetName string
param subscriptionId string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param vNetDnsServers array

var delegations = {
  'azure-netapp-files': [
    {
      name: 'Microsoft.Netapp.volumes'
      id: resourceId('Microsoft.Network/virtualNetworks/subnets/delegations', virtualNetworkName, 'azure-netapp-files', 'delegation')
      properties: {
        serviceName: 'Microsoft.Netapp/volumes'
      }
      type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
    }
  ]
  'function-app-outbound': [
    {
      name: 'Microsoft.Web/sites'
      id: resourceId('Microsoft.Network/virtualNetworks/subnets/delegations', virtualNetworkName, 'function-app-outbound', 'delegation')
      properties: {
        serviceName: 'Microsoft.Web/serverfarms'
      }
      type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
    }
  ]
}
var subnets = union([
  {
    name: subnetName
    properties: {
      addressPrefix: subnetAddressPrefix
    }
  }
], additionalSubnets)

module networkSecurityGroup '../modules/network-security-group.bicep' = {
  name: 'networkSecurityGroup'
  scope: resourceGroup(subscriptionId, resourceGroupName)
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
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    disableBgpRoutePropagation: true
    location: location
    mlzTags: mlzTags
    name: routeTableName
    routeNextHopIpAddress: routeTableRouteNextHopIpAddress
    tags: tags
  }
}

module virtualNetwork '../modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    addressPrefix: virtualNetworkAddressPrefix
    location: location
    mlzTags: mlzTags
    name: virtualNetworkName
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.properties.addressPrefix
        defaultOutboundAccess: false
        delegations: delegations[?subnet.name] ?? []
        networkSecurityGroup: {
          id: networkSecurityGroup.outputs.id
        }
        routeTable: {
          id: routeTable.outputs.id
        }
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Disabled'
      }
    }]
    tags: tags
    vNetDnsServers: vNetDnsServers
  }
}

output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  networkSecurityGroup.outputs.id
output subnets array = virtualNetwork.outputs.subnets
output virtualNetworkAddressPrefix string = virtualNetwork.outputs.addressPrefix
output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
