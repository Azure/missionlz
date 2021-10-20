param location string = resourceGroup().location
param tags object = {}

param logStorageAccountName string
param logStorageSkuName string

param logAnalyticsWorkspaceResourceId string

param firewallPrivateIPAddress string

param virtualNetworkName string
param virtualNetworkAddressPrefix string
param virtualNetworkDiagnosticsLogs array
param virtualNetworkDiagnosticsMetrics array

param networkSecurityGroupName string
param networkSecurityGroupRules array

param networkSecurityGroupDiagnosticsLogs array
param networkSecurityGroupDiagnosticsMetrics array

param subnetName string
param subnetAddressPrefix string
param subnetServiceEndpoints array

param routeTableName string = '${subnetName}-routetable'
param routeTableRouteName string = 'default_route'
param routeTableRouteAddressPrefix string = '0.0.0.0/0'
param routeTableRouteNextHopIpAddress string = firewallPrivateIPAddress
param routeTableRouteNextHopType string = 'VirtualAppliance'

module logStorage './storageAccount.bicep' = {
  name: 'logStorage'
  params: {
    storageAccountName: logStorageAccountName
    location: location
    skuName: logStorageSkuName
    tags: tags
  }
}

module networkSecurityGroup './networkSecurityGroup.bicep' = {
  name: 'networkSecurityGroup'
  params: {
    name: networkSecurityGroupName
    location: location
    tags: tags

    securityRules: networkSecurityGroupRules
    
    logs: networkSecurityGroupDiagnosticsLogs
    metrics: networkSecurityGroupDiagnosticsMetrics
    
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id
  }
}

module routeTable './routeTable.bicep' = {
  name: 'routeTable'
  params: {
    name: routeTableName
    location: location
    tags: tags

    routeName: routeTableRouteName
    routeAddressPrefix: routeTableRouteAddressPrefix
    routeNextHopIpAddress: routeTableRouteNextHopIpAddress
    routeNextHopType: routeTableRouteNextHopType
  }
}

module virtualNetwork './virtualNetwork.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: virtualNetworkName
    location: location
    tags: tags

    addressPrefix: virtualNetworkAddressPrefix

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
          serviceEndpoints: subnetServiceEndpoints
        }
      }
    ]

    logs: virtualNetworkDiagnosticsLogs
    metrics: virtualNetworkDiagnosticsMetrics

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id
  }
}

output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
output subnetName string = virtualNetwork.outputs.subnets[0].name
output subnetAddressPrefix string = virtualNetwork.outputs.subnets[0].properties.addressPrefix
output subnetResourceId string = virtualNetwork.outputs.subnets[0].id
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string =  networkSecurityGroup.outputs.id
