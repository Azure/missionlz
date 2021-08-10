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

param subnetName string
param subnetAddressPrefix string
param subnetServiceEndpoints array

param routeTableName string = '${subnetName}-routetable'
param routeTableRouteName string = 'default_route'
param routeTableRouteAddressPrefix string = '0.0.0.0/0'
param routeTableRouteNextHopIpAddress string = firewallPrivateIPAddress
param routeTableRouteNextHopType string = 'VirtualAppliance'

var defaultVirtualNetworkDiagnosticsLogs = [
  // TODO: 'VMProtectionAlerts' is not supported in AzureUsGovernment
  // {
  //   category: 'VMProtectionAlerts'
  //   enabled: true
  // }
]

var defaultVirtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

var defaultSubnetServiceEndpoints = [
  {
    service: 'Microsoft.Storage'
  }
]

var defaultNetworkSecurityGroupRules = [
  {
    name: 'allow_ssh'
    properties: {
      description: 'Allow SSH access from anywhere'
      access: 'Allow'
      priority: 100
      protocol: 'Tcp'
      direction: 'Inbound'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '22'
      destinationAddressPrefix: '*'
    }
  }
  {
    name: 'allow_rdp'
    properties: {
      description: 'Allow RDP access from anywhere'
      access: 'Allow'
      priority: 200
      protocol: 'Tcp'
      direction: 'Inbound'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '3389'
      destinationAddressPrefix: '*'
    }
  }
]

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

    securityRules: empty(networkSecurityGroupRules) ? defaultNetworkSecurityGroupRules : networkSecurityGroupRules
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

    diagnosticsLogs: empty(virtualNetworkDiagnosticsLogs) ? defaultVirtualNetworkDiagnosticsLogs : virtualNetworkDiagnosticsLogs
    diagnosticsMetrics: empty(virtualNetworkDiagnosticsMetrics) ? defaultVirtualNetworkDiagnosticsMetrics : virtualNetworkDiagnosticsMetrics

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
          serviceEndpoints: empty(subnetServiceEndpoints) ? defaultSubnetServiceEndpoints : subnetServiceEndpoints
        }
      }
    ]

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
