/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param azureGatewaySubnetAddressPrefix string
param bastionHostNetworkSecurityGroup string
param bastionHostSubnetAddressPrefix string
param deployAzureGatewaySubnet bool
param deployBastion bool
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

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallThreatIntelMode string
param location string
param mlzTags object
param networkSecurityGroupName string
param networkSecurityGroupRules array
param routeTableName string
param subnetAddressPrefix string
param subnetName string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param vNetDnsServers array
param firewallRuleCollectionGroups array

var subnets = union([
  {
    name: 'AzureFirewallSubnet'
    properties: {
      addressPrefix: firewallClientSubnetAddressPrefix
      defaultOutboundAccess: false
    }
  }
  {
    name: 'AzureFirewallManagementSubnet'
    properties: {
      addressPrefix: firewallManagementSubnetAddressPrefix
      defaultOutboundAccess: false
    }
  }
  {
    name: subnetName
    properties: {
      addressPrefix: subnetAddressPrefix
      defaultOutboundAccess: false
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
      defaultOutboundAccess: false
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
      defaultOutboundAccess: false
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
    intrusionDetectionMode: firewallIntrusionDetectionMode
    location: location
    managementIpConfigurationPublicIPAddressResourceId: firewallManagementPublicIPAddress.outputs.id
    managementIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallManagementSubnet'
    mlzTags: mlzTags
    name: firewallName
    skuTier: firewallSkuTier
    tags: tags
    threatIntelMode: firewallThreatIntelMode
    firewallRuleCollectionGroups: firewallRuleCollectionGroups
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

