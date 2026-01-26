/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param additionalSubnets array = []
param delimiter string
param customSubnetName string = ''
param location string
param mlzTags object
param resourceGroupName string
param routeTableRouteNextHopIpAddress string
param tags object
param tier object
param tokens object
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
    name: empty(customSubnetName) ? replace(tier.namingConvention.subnet, '${delimiter}${tokens.purpose}', '') : customSubnetName
    properties: {
      addressPrefix: tier.subnetAddressPrefix
    }
  }
], additionalSubnets)
var subscriptionId = tier.subscriptionId
var virtualNetworkName = replace(tier.namingConvention.virtualNetwork, '${delimiter}${tokens.purpose}', '')

module networkSecurityGroup '../modules/network-security-group.bicep' = {
  name: 'networkSecurityGroup'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.networkSecurityGroup, '${delimiter}${tokens.purpose}', '')
    securityRules: tier.nsgRules
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
    name: replace(tier.namingConvention.routeTable, '${delimiter}${tokens.purpose}', '')
    routeNextHopIpAddress: routeTableRouteNextHopIpAddress
    tags: tags
  }
}

module virtualNetwork '../modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    addressPrefix: tier.vnetAddressPrefix
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
