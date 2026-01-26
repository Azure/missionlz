/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param azureGatewaySubnetAddressPrefix string
param bastionHostSubnetAddressPrefix string
param delimiter string
param deployAzureGatewaySubnet bool
param deployBastion bool
param deploymentNameSuffix string
param dnsServers array
param enableProxy bool
param firewallClientPrivateIpAddress string
param firewallClientPublicIPAddressAvailabilityZones array
param firewallClientSubnetAddressPrefix string
param firewallCustomPipCount int
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallIntrusionDetectionMode string
param firewallManagementPublicIPAddressAvailabilityZones array
param firewallManagementSubnetAddressPrefix string
param firewallRuleCollectionGroups array
param firewallSkuTier string

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallThreatIntelMode string
param location string
param mlzTags object
param resourceGroupName string
param subscriptionId string
param tags object
param tier object
param tokens object
param vNetDnsServers array

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
    name: replace(tier.namingConvention.subnet, '${delimiter}${tokens.purpose}', '')
    properties: {
      addressPrefix: tier.subnetAddressPrefix
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
  name: 'deploy-hub-nsg-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.networkSecurityGroup, '${delimiter}${tokens.purpose}', '')
    securityRules: tier.nsgRules
    tags: tags
  }
}

module bastionNetworkSecurityGroup '../modules/network-security-group.bicep' = if (deployBastion) {
  name: 'deploy-hub-bastion-nsg-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.bastionHostNetworkSecurityGroup, '${delimiter}${tokens.purpose}', '')
    securityRules: bastionNetworkSecurityGroupRules
    tags: tags
  }
}

module routeTable '../modules/route-table.bicep' = {
  name: 'deploy-hub-rt-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    disableBgpRoutePropagation: false
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.routeTable, '${delimiter}${tokens.purpose}', '')
    routeNextHopIpAddress: firewallClientPrivateIpAddress
    tags: tags
  }
}

module virtualNetwork '../modules/virtual-network.bicep' = {
  name: 'deploy-hub-vnet-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    addressPrefix: tier.vnetAddressPrefix
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.virtualNetwork, '${delimiter}${tokens.purpose}', '')
    subnets: subnets
    tags: tags
    vNetDnsServers: vNetDnsServers
  }
}

module firewallClientPublicIPAddress '../modules/public-ip-address.bicep' = {
  name: 'deploy-hub-fw-client-pip-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilityZones: firewallClientPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.azureFirewallPublicIPAddress, tokens.purpose, 'client')
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
    tags: tags
  }
}

module firewallManagementPublicIPAddress '../modules/public-ip-address.bicep' = {
  name: 'deploy-hub-fw-mgmt-pip-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilityZones: firewallManagementPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: replace(tier.namingConvention.azureFirewallPublicIPAddress, tokens.purpose, 'management')
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
    tags: tags
  }
}

module firewallCustomPublicIPAddresses '../modules/public-ip-address.bicep' = [for i in range(1, firewallCustomPipCount): if (firewallCustomPipCount > 0) {
  name: 'deploy-hub-fw-custom-pip-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    availabilityZones: firewallClientPublicIPAddressAvailabilityZones
    location: location
    mlzTags: mlzTags
    name: '${replace(tier.namingConvention.azureFirewallPublicIPAddress, tokens.purpose, 'client')}${delimiter}${i}'
    publicIpAllocationMethod: 'Static'
    skuName: 'Standard'
    tags: tags
  }
}]

module firewall '../modules/firewall.bicep' = {
  name: 'deploy-hub-fw-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    clientIpConfigurationPublicIPAddressResourceId: firewallClientPublicIPAddress.outputs.id
    clientIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallSubnet'
    customPipCount: firewallCustomPipCount
    customPublicIPAddressNamePrefix: '${replace(tier.namingConvention.azureFirewallPublicIPAddress, tokens.purpose, 'client')}${delimiter}'
    dnsServers: dnsServers
    enableProxy: enableProxy
    firewallPolicyName: replace(tier.namingConvention.azureFirewallPolicy, '${delimiter}${tokens.purpose}', '')
    intrusionDetectionMode: firewallIntrusionDetectionMode
    location: location
    managementIpConfigurationPublicIPAddressResourceId: firewallManagementPublicIPAddress.outputs.id
    managementIpConfigurationSubnetResourceId: '${virtualNetwork.outputs.id}/subnets/AzureFirewallManagementSubnet'
    mlzTags: mlzTags
    name: replace(tier.namingConvention.azureFirewall, '${delimiter}${tokens.purpose}', '')
    resourceGroupName: resourceGroupName
    skuTier: firewallSkuTier
    subscriptionId: subscriptionId
    tags: tags
    threatIntelMode: firewallThreatIntelMode
    firewallRuleCollectionGroups: firewallRuleCollectionGroups
  }
  dependsOn: [
    firewallCustomPublicIPAddresses
  ]
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
