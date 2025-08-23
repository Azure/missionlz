param firewallPolicyName string
param hubVirtualNetworkResourceId string
param virtualNetworkResourceIdList array
param localAddressPrefixes array = []
param firewallRuleCollectionGroups array = []

// Existing firewall policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-03-01' existing = {
  name: firewallPolicyName
}

// Existing hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: last(split(hubVirtualNetworkResourceId, '/'))
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
}

// Existing VNets provided
resource vnets 'Microsoft.Network/virtualNetworks@2023-11-01' existing = [for (vnetId, i) in virtualNetworkResourceIdList: {
  name: last(split(vnetId, '/'))
  scope: resourceGroup(split(vnetId, '/')[2], split(vnetId, '/')[4])
}]

// If custom rule groups are provided, deploy them as-is
@batchSize(1)
resource ruleGroupsCustom 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = [for (group, i) in firewallRuleCollectionGroups: {
  parent: firewallPolicy
  name: group.name
  properties: group.properties
}]

// Otherwise, generate defaults: hub <-> spokes and onprem <-> hub/spokes per spoke
@batchSize(1)
resource ruleGroupsDefault 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = [for (vnetId, i) in virtualNetworkResourceIdList: if (empty(firewallRuleCollectionGroups)) {
  parent: firewallPolicy
  name: 'VGW-Vnet-${i}'
  properties: {
    priority: 300 + i
    ruleCollections: [
      {
        name: 'AllowHubSpoke-${i}'
        priority: 150
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: concat([
          {
            name: 'AllowHubToVnet-${i}'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: hubVnet.properties.addressSpace.addressPrefixes
            destinationAddresses: vnets[i].properties.addressSpace.addressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
          {
            name: 'AllowVnetToHub-${i}'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: vnets[i].properties.addressSpace.addressPrefixes
            destinationAddresses: hubVnet.properties.addressSpace.addressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
        ], !empty(localAddressPrefixes) ? [
          // Hub <-> On-prem
          {
            name: 'AllowHubToOnPrem-${i}'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: hubVnet.properties.addressSpace.addressPrefixes
            destinationAddresses: localAddressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
          {
            name: 'AllowOnPremToHub-${i}'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: localAddressPrefixes
            destinationAddresses: hubVnet.properties.addressSpace.addressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
          // Spoke <-> On-prem
          {
            name: 'AllowOnPremToVnet-${i}'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: localAddressPrefixes
            destinationAddresses: vnets[i].properties.addressSpace.addressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
          {
            name: 'AllowVnetToOnPrem-${i}'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: vnets[i].properties.addressSpace.addressPrefixes
            destinationAddresses: localAddressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
        ] : [])
      }
    ]
  }
}]
