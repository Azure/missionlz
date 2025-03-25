param firewallPolicyName string
param resourcePrefix string
param environmentAbbreviation string

// get the firewall policy name from the parameters and pull the existing resource
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-08-01' existing = {
  name: firewallPolicyName
}

// Define appliation layer rule collection group for the firewall policy in MLZ
var appRuleCollctionGroup = {
  properties: {
    priority: 300
    ruleCollections: [
      {
        name: 'AzureAuth'
        priority: 110
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'msftauth'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              'aadcdn.msftauth.net'
              'aadcdn.msauth.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: ['*']
            destinationAddresses: []
            sourceIpGroups: []
          }
        ]
      }
    ]
  }
}

// Define network rule collection group for the firewall policy in MLZ
var networkRuleCollectionGroup = {
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'AllowAzureCloud'
        priority: 100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'AzureCloud'
            ruleType: 'NetworkRule'
            ipProtocols: ['Any']
            sourceAddresses: ['*']
            sourceIpGroups: []
            destinationAddresses: ['AzureCloud']
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: ['*']
          }
        ]
      }
    ]
  }
} 

// Azure Firewall Policy Rule Collection Group for Application Rules
resource appRuleCreate'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  parent: firewallPolicy
  name: '${resourcePrefix}-${environmentAbbreviation}-AppRuleCollectionGroup'
  properties: appRuleCollctionGroup.properties
}

// Azure Firewall Policy Rule Collection Group for Network Rules
resource networkRuleCreate 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  parent: firewallPolicy
  name: '${resourcePrefix}-${environmentAbbreviation}-NetworkRuleCollectionGroup'
  properties: networkRuleCollectionGroup.properties
  dependsOn: [
    appRuleCreate
  ]
}
