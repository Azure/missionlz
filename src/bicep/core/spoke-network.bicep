/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string = resourceGroup().location
param tags object = {}

param logStorageAccountName string
param logStorageSkuName string

param logAnalyticsWorkspaceResourceId string

param firewallPrivateIPAddress string

param virtualNetworkName string
param virtualNetworkAddressPrefixes array
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array

param networkSecurityGroupName string
param networkSecurityGroupRules array

param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array

param subnets array

param routeTableRouteName string = 'default_route'
param routeTableRouteAddressPrefix string = '0.0.0.0/0'
param routeTableRouteNextHopIpAddress string = firewallPrivateIPAddress
param routeTableRouteNextHopType string = 'VirtualAppliance'

module logStorage '../modules/storage-account.bicep' = {
  name: 'logStorage'
  params: {
    storageAccountName: logStorageAccountName
    location: location
    skuName: logStorageSkuName
    tags: tags
  }
}

module networkSecurityGroup '../modules/network-security-group.bicep' = {
  name: 'networkSecurityGroup'
  params: {
    name: networkSecurityGroupName
    location: location
    tags: tags

    securityRules: networkSecurityGroupRules
    
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: networkSecurityGroupDiagnosticsLogs
    metrics: networkSecurityGroupDiagnosticsMetrics
  }
}

module routeTable '../modules/route-table.bicep' = [for subnet in subnets:{
  name: '${subnet.subnetName}-routetable'
  params: {
    name: '${subnet.subnetName}-routetable'
    location: location
    tags: tags

    routeName: routeTableRouteName
    routeAddressPrefix: routeTableRouteAddressPrefix
    routeNextHopIpAddress: routeTableRouteNextHopIpAddress
    routeNextHopType: routeTableRouteNextHopType
  }
}]

module virtualNetwork '../modules/virtual-network.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: virtualNetworkName
    location: location
    tags: tags

    addressPrefixes: virtualNetworkAddressPrefixes

    subnets: [for subnet in subnets:{
        name: subnet.subnetName
        properties: {
          addressPrefix: subnet.subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.outputs.id
          }
          routeTable: {
            id: resourceId(resourceGroup().name,'Microsoft.Network/routeTables','${subnet.subnetName}-routetable')
          }
          serviceEndpoints: subnet.subnetServiceEndpoints
        }
      }]

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: virtualNetworkDiagnosticsLogs
    metrics: virtualNetworkDiagnosticsMetrics
  }
  dependsOn: [
    routeTable
  ]
}

output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
output virtualNetworkAddressPrefixes array = virtualNetwork.outputs.addressPrefixes
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  networkSecurityGroup.outputs.id
output subnets array = virtualNetwork.outputs.subnets
