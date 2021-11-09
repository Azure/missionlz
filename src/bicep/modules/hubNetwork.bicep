param location string = resourceGroup().location
param tags object = {}

param logStorageAccountName string
param logStorageSkuName string

param logAnalyticsWorkspaceName string
param logAnalyticsWorkspaceResourceId string

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
param routeTableRouteNextHopType string = 'VirtualAppliance'

param firewallName string
param firewallSkuTier string
param firewallPolicyName string
param firewallThreatIntelMode string
param firewallDiagnosticsLogs array
param firewallDiagnosticsMetrics array
param firewallClientIpConfigurationName string
param firewallClientSubnetName string
param firewallClientSubnetAddressPrefix string
param firewallClientSubnetServiceEndpoints array
param firewallClientPublicIPAddressName string
param firewallClientPublicIPAddressSkuName string
param firewallClientPublicIpAllocationMethod string
param firewallClientPublicIPAddressAvailabilityZones array
param firewallManagementIpConfigurationName string
param firewallManagementSubnetName string
param firewallManagementSubnetAddressPrefix string
param firewallManagementSubnetServiceEndpoints array
param firewallManagementPublicIPAddressName string
param firewallManagementPublicIPAddressSkuName string
param firewallManagementPublicIpAllocationMethod string
param firewallManagementPublicIPAddressAvailabilityZones array

param publicIPAddressDiagnosticsLogs array
param publicIPAddressDiagnosticsMetrics array

param supportedClouds array = [
  'AzureCloud'
  'AzureUSGovernment'
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

    securityRules: networkSecurityGroupRules

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: networkSecurityGroupDiagnosticsLogs
    metrics: networkSecurityGroupDiagnosticsMetrics
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
        name: firewallClientSubnetName
        properties: {
          addressPrefix: firewallClientSubnetAddressPrefix
          serviceEndpoints: firewallClientSubnetServiceEndpoints
        }
      }
      {
        name: firewallManagementSubnetName
        properties: {
          addressPrefix: firewallManagementSubnetAddressPrefix
          serviceEndpoints: firewallManagementSubnetServiceEndpoints
        }
      }
    ]

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: virtualNetworkDiagnosticsLogs
    metrics: virtualNetworkDiagnosticsMetrics
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
    routeNextHopIpAddress: firewall.outputs.privateIPAddress
    routeNextHopType: routeTableRouteNextHopType
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${virtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: networkSecurityGroup.outputs.id
    }
    routeTable: {
      id: routeTable.outputs.id
    }
    serviceEndpoints: subnetServiceEndpoints    
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    virtualNetwork
    firewall
  ]
}

module firewallClientPublicIPAddress './publicIPAddress.bicep' = {
  name: 'firewallClientPublicIPAddress'
  params: {
    name: firewallClientPublicIPAddressName
    location: location
    tags: tags

    skuName: firewallClientPublicIPAddressSkuName
    publicIpAllocationMethod: firewallClientPublicIpAllocationMethod
    availabilityZones: firewallClientPublicIPAddressAvailabilityZones

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: publicIPAddressDiagnosticsLogs
    metrics: publicIPAddressDiagnosticsMetrics
  }
}

module firewallManagementPublicIPAddress './publicIPAddress.bicep' = {
  name: 'firewallManagementPublicIPAddress'
  params: {
    name: firewallManagementPublicIPAddressName
    location: location
    tags: tags

    skuName: firewallManagementPublicIPAddressSkuName
    publicIpAllocationMethod: firewallManagementPublicIpAllocationMethod
    availabilityZones: firewallManagementPublicIPAddressAvailabilityZones

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: publicIPAddressDiagnosticsLogs
    metrics: publicIPAddressDiagnosticsMetrics
  }
}

module firewall './firewall.bicep' = {
  name: 'firewall'
  params: {
    name: firewallName
    location: location
    tags: tags

    skuTier: firewallSkuTier

    firewallPolicyName: firewallPolicyName
    threatIntelMode: firewallThreatIntelMode

    clientIpConfigurationName: firewallClientIpConfigurationName
    clientIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/${firewallClientSubnetName}'
    clientIpConfigurationPublicIPAddressResourceId: firewallClientPublicIPAddress.outputs.id

    managementIpConfigurationName: firewallManagementIpConfigurationName
    managementIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/${firewallManagementSubnetName}'
    managementIpConfigurationPublicIPAddressResourceId: firewallManagementPublicIPAddress.outputs.id
    
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    logStorageAccountResourceId: logStorage.outputs.id

    logs: firewallDiagnosticsLogs
    metrics: firewallDiagnosticsMetrics
  }
}

module azureMonitorPrivateLink './privateLink.bicep' = if ( contains(supportedClouds, environment().name) ){
  name: 'azure-monitor-private-link'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    privateEndpointSubnetName: subnetName
    privateEndpointVnetName: virtualNetwork.outputs.name
    tags: tags
  }
  dependsOn: [
    subnet
  ]
}

output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
output subnetName string = subnet.name
output subnetAddressPrefix string = subnet.properties.addressPrefix
output subnetResourceId string = subnet.id
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string = networkSecurityGroup.outputs.id
output firewallPrivateIPAddress string = firewall.outputs.privateIPAddress
