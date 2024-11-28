@description('The list of virtual network resource IDs to be used as the source IP groups')
param allowVnetAddressSpaces array

@description('Address prefixes of the on-premises network')
param onPremAddressSpaces array

@description('Name of the firewall policy')
param firewallPolicyId string

@description('The priority value for the rule collection')
@minValue(300)
@maxValue(65000)
param priorityValue int


// Define the firewall policy reference
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-04-01' existing = {
  name: last(split(firewallPolicyId, '/'))
}

// First rule set: Source = allowedIpGroup, Destination = onPremIpGroup
var outboundRules = {
  name: 'AllowAzureToOnPremRule' // Unique rule name using index
  ruleType: 'NetworkRule'
  sourceAddresses: allowVnetAddressSpaces
  destinationAddresses: onPremAddressSpaces
  destinationPorts: [
    '*'  // Modify this as needed
  ]
  ipProtocols: [
    'Any'  // Modify this as needed
  ]
}

// Second rule set (reverse): Source = onPremIpGroup, Destination = allowedIpGroup
var inboundRules = {
  name: 'AllowOnPremToAzureRule' // Unique rule name using index
  ruleType: 'NetworkRule'
  sourceAddresses: onPremAddressSpaces
  destinationAddresses: allowVnetAddressSpaces
  destinationPorts: [
    '*'  // Modify this as needed
  ]
  ipProtocols: [
    'Any'  // Modify this as needed
  ]
}

// Define the rule collection group, referencing existing IP groups for source and destination
resource allowVgwCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
  name: 'VgwNetworkRuleCollectionGroup'
  parent: firewallPolicy
  properties: {
    priority: priorityValue
    ruleCollections: [
      {
        name: 'AllowVgw'
        priority: priorityValue
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          outboundRules
          inboundRules
        ] 
      }
    ]
  }
}
