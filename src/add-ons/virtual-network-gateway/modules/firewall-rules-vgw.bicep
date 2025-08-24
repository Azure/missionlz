param firewallPolicyName string
@description('The resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string
param virtualNetworkResourceIdList array
param localAddressPrefixes array = []
param firewallRuleCollectionGroups array = []

// Existing firewall policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-03-01' existing = {
  name: firewallPolicyName
}

// Existing Hub VNet
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

// Otherwise, generate defaults: a single group with OnPrem <-> Spokes rules
resource ruleGroupDefault 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = if (empty(firewallRuleCollectionGroups) && !empty(localAddressPrefixes)) {
  parent: firewallPolicy
  name: 'VGW-OnPrem'
  properties: {
    priority: 245
    ruleCollections: [
      {
        name: 'AllowOnPremToSpokes'
        priority: 130
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          for (vnetId, i) in virtualNetworkResourceIdList: {
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
        ]
      }
      {
        name: 'AllowSpokesToOnPrem'
        priority: 131
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          for (vnetId, i) in virtualNetworkResourceIdList: {
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
        ]
      }
      {
        name: 'AllowOnPremToHub'
        priority: 132
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'AllowOnPremToHub-All'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: localAddressPrefixes
            destinationAddresses: hubVnet.properties.addressSpace.addressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
        ]
      }
      {
        name: 'AllowHubToOnPrem'
        priority: 133
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'AllowHubToOnPrem-All'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: hubVnet.properties.addressSpace.addressPrefixes
            destinationAddresses: localAddressPrefixes
            destinationPorts: ['*']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
        ]
      }
    ]
  }
}
