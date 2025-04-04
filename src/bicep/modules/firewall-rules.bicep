param firewallPolicyName string
param firewallRuleCollectionGroups array

// get the firewall policy name from the parameters and pull the existing resource
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-03-01' existing = {
  name: firewallPolicyName
}

// Create ruleset for each passed firewallRuleCollectionGroup
@batchSize(1)
resource ruleCreate 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = [for group in firewallRuleCollectionGroups: {
  parent: firewallPolicy
  name: group.name
  properties: group.properties
}]  



