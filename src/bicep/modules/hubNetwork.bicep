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

var defaultVirtualNewtorkDiagnosticsLogs = [
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

module virtualNetwork './virtualNetwork.bicep' = {
  name: 'virtualNetwork'
  params: {
    name: virtualNetworkName
    location: location
    tags: tags

    addressPrefix: virtualNetworkAddressPrefix

    diagnosticsLogs: empty(virtualNetworkDiagnosticsLogs) ? defaultVirtualNewtorkDiagnosticsLogs : virtualNetworkDiagnosticsLogs
    diagnosticsMetrics: empty(virtualNetworkDiagnosticsMetrics) ? defaultVirtualNetworkDiagnosticsMetrics : virtualNetworkDiagnosticsMetrics

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
    serviceEndpoints: empty(subnetServiceEndpoints) ? defaultSubnetServiceEndpoints : subnetServiceEndpoints    
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
  }
}

module azureMonitorPrivateLink './privateLink.bicep' = {
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
