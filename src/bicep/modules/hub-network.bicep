/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param bastionHostNetworkSecurityGroup string
param bastionHostSubnetAddressPrefix string
param azureGatewaySubnetAddressPrefix string
param deployNetworkWatcher bool
param deployBastion bool
param deployAzureGatewaySubnet bool
param deployAzureNATGateway bool
param dnsServers array
param enableProxy bool
param firewallClientPrivateIpAddress string
param firewallClientPublicIPAddressAvailabilityZones array
param firewallClientPublicIPAddressName string
param firewallClientSubnetAddressPrefix string
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallIntrusionDetectionMode string
param firewallManagementPublicIPAddressAvailabilityZones array
param firewallManagementPublicIPAddressName string
param firewallManagementSubnetAddressPrefix string
param firewallName string
param firewallPolicyName string
param firewallSkuTier string
param firewallSupernetIPAddress string
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallThreatIntelMode string
param location string
param mlzTags object
param natGatewayName string
param natGatewayPublicIpPrefixName string
param natGatewayPublicIpPrefixLength int
param networkSecurityGroupName string
param networkSecurityGroupRules array
param networkWatcherName string
param routeTableName string
param subnetAddressPrefix string
param subnetName string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param vNetDnsServers array

var subnets = union([
  {
    name: 'AzureFirewallSubnet'
    properties: {
      addressPrefix: firewallClientSubnetAddressPrefix
      natGateway: deployAzureNATGateway ? { id: natGateway.outputs.id } : null
    }
  }
  {
    name: 'AzureFirewallManagementSubnet'
    properties: {
      addressPrefix: firewallManagementSubnetAddressPrefix
    }
  }
  {
    name: subnetName
    properties: {
      addressPrefix: subnetAddressPrefix
      natGateway: deployAzureNATGateway ? { id: natGateway.outputs.id } : null
      networkSecurityGroup: {
        id: networkSecurityGroup.outputs.id
      }
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Disabled'
      routeTable: {
        id: routeTable.outputs.id
      }
    }
  }
], deployBastion ? [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionHostSubnetAddressPrefix
      networkSecurityGroup: {
        id: bastionNetworkSecurityGroup.outputs.id
      }
    }
  } 
] : [], deployAzureGatewaySubnet ? [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: azureGatewaySubnetAddressPrefix
    }
  }
] : [])

//array for bastion nsg

var bastionNetworkSecurityGroupRules = [
  {
    name: 'AllowHttpsInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowGatewayManagerInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'GatewayManager'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 130
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowLoadBalancerInBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationPortRange: '443'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 140
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowBastionHostCommunicationInBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 150
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowSshRdpOutBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRanges: [
        '22'
        '3389'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 120
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowAzureCloudCommunicationOutBound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationPortRange: '443'
      destinationAddressPrefix: 'AzureCloud'
      access: 'Allow'
      priority: 130
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowBastionHostCommunicationOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 140
      direction: 'Outbound'
    }
  }
  {
    name: 'AllowGetSessionInformationOutBound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      sourceAddressPrefix: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRanges: [
        '80'
        '443'
      ]
      access: 'Allow'
      priority: 150
      direction: 'Outbound'
    }
  }
]

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


module bastionNetworkSecurityGroup '../modules/network-security-group.bicep' = if (deployBastion) {
  name: 'bastionNSG'
  params: {
    location: location
    mlzTags: mlzTags
    name: bastionHostNetworkSecurityGroup
    securityRules: bastionNetworkSecurityGroupRules
    tags: tags
  }
}

module routeTable '../modules/route-table.bicep' = {
  name: 'routeTable'
  params: {
    disableBgpRoutePropagation: false
    location: location
    mlzTags: mlzTags
    name: routeTableName
    routeNextHopIpAddress: firewallClientPrivateIpAddress
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
    subnets: subnets
    tags: tags
    vNetDnsServers: vNetDnsServers
  }
  dependsOn: [
    networkWatcher
  ]
}

module firewallClientPublicIPAddress '../modules/public-ip-address.bicep' = {
  name: 'firewallClientPublicIPAddress'
  params: {
    availabilityZones: firewallClientPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: firewallClientPublicIPAddressName
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
    tags: tags
  }
}

module firewallManagementPublicIPAddress '../modules/public-ip-address.bicep' = {
  name: 'firewallManagementPublicIPAddress'
  params: {
    availabilityZones: firewallManagementPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: firewallManagementPublicIPAddressName
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
    tags: tags
  }
}

module firewall '../modules/firewall.bicep' = {
  name: 'firewall'
  params: {
    clientIpConfigurationPublicIPAddressResourceId: firewallClientPublicIPAddress.outputs.id
    clientIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallSubnet'
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallPolicyName: firewallPolicyName
    firewallSupernetIPAddress: firewallSupernetIPAddress
    intrusionDetectionMode: firewallIntrusionDetectionMode
    location: location
    managementIpConfigurationPublicIPAddressResourceId: firewallManagementPublicIPAddress.outputs.id
    managementIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallManagementSubnet'
    mlzTags: mlzTags
    name: firewallName
    skuTier: firewallSkuTier
    tags: tags
    threatIntelMode: firewallThreatIntelMode
  }
}

module natGatewayPublicIpPrefix '../modules/public-ip-prefix.bicep' = if (deployAzureNATGateway) {
  name: 'natGatewayPublicIpPrefix'
  params: {
    location: location
    mlzTags: mlzTags
    name: natGatewayPublicIpPrefixName
    prefixLength: natGatewayPublicIpPrefixLength
    tags: tags
  }
}

module natGateway '../modules/nat-gateway.bicep' = if (deployAzureNATGateway) {
  name: 'natGateway'
  params: {
    location: location
    mlzTags: mlzTags
    name: natGatewayName
    publicIPPrefixResourceIds: [
      {
        id: natGatewayPublicIpPrefix.outputs.id
      }
    ]
    tags: tags
  }
}

output bastionHostSubnetResourceId string = deployBastion ? virtualNetwork.outputs.subnets[3].id : ''
output dnsServers array = virtualNetwork.outputs.dnsServers
output firewallName string = firewall.outputs.name
output firewallPrivateIPAddress string = firewall.outputs.privateIPAddress
output firewallResourceId string = firewall.outputs.resourceId
output networkSecurityGroupName string = networkSecurityGroup.outputs.name
output networkSecurityGroupResourceId string = networkSecurityGroup.outputs.id
output subnetAddressPrefix string = virtualNetwork.outputs.subnets[2].properties.addressPrefix
output subnetName string = virtualNetwork.outputs.subnets[2].name
output subnetResourceId string = virtualNetwork.outputs.subnets[2].id
output virtualNetworkName string = virtualNetwork.outputs.name
output virtualNetworkResourceId string = virtualNetwork.outputs.id
output natGatewayPublicIpPrefixName string = natGatewayPublicIpPrefix.outputs.name
output natGatewayPublicIpPrefixResourceId string = natGatewayPublicIpPrefix.outputs.id
output natGatewayName string = natGateway.outputs.name
output natGatewayResourceId string = natGateway.outputs.id
