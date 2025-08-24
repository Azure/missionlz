param firewallPolicyName string
@description('Address prefixes of the Hub virtual network.')
param hubAddressPrefixes array
@description('List of address prefix arrays for each Spoke VNet (e.g., [["10.2.0.0/16"],["10.3.0.0/16","10.3.1.0/24"]]).')
param spokeAddressPrefixSets array
param localAddressPrefixes array = []
param firewallRuleCollectionGroups array = []
@description('Include Hub <-> On-Prem allow rules in the default rule group')
param includeHubOnPrem bool = false

// Existing firewall policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-03-01' existing = {
  name: firewallPolicyName
}

// No existing VNet resources are referenced in this module; addresses are provided directly via parameters.

// Build rule arrays up-front (allowed at start of deployment since only params used)
var onPremToSpokesRules = [
  for (prefixes, i) in spokeAddressPrefixSets: {
    name: 'AllowOnPremToVnet-${i}'
    ruleType: 'NetworkRule'
    ipProtocols: ['Any']
    sourceAddresses: localAddressPrefixes
    destinationAddresses: prefixes
    destinationPorts: ['*']
    sourceIpGroups: []
    destinationIpGroups: []
    destinationFqdns: []
  }
]

var spokesToOnPremRules = [
  for (prefixes, i) in spokeAddressPrefixSets: {
    name: 'AllowVnetToOnPrem-${i}'
    ruleType: 'NetworkRule'
    ipProtocols: ['Any']
    sourceAddresses: prefixes
    destinationAddresses: localAddressPrefixes
    destinationPorts: ['*']
    sourceIpGroups: []
    destinationIpGroups: []
    destinationFqdns: []
  }
]

var baseRuleCollections = [
  {
    name: 'AllowOnPremToSpokes'
    priority: 130
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: onPremToSpokesRules
  }
  {
    name: 'AllowSpokesToOnPrem'
    priority: 131
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: {
      type: 'Allow'
    }
    rules: spokesToOnPremRules
  }
]

var hubRuleCollections = [
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
        destinationAddresses: hubAddressPrefixes
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
        sourceAddresses: hubAddressPrefixes
        destinationAddresses: localAddressPrefixes
        destinationPorts: ['*']
        sourceIpGroups: []
        destinationIpGroups: []
        destinationFqdns: []
      }
    ]
  }
]

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
  ruleCollections: concat(baseRuleCollections, includeHubOnPrem ? hubRuleCollections : [])
  }
}
