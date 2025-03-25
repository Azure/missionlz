using './mlz.bicep'

param resourcePrefix = 'sample'
param firewallRuleCollectionGroups = [
  {
    Name: 'defaultApplicationCollectionGroup'
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
  {
  name: 'defaultNetworkCollectionGroup'
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
]

