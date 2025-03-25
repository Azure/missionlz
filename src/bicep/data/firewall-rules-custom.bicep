param firewallPolicyName string
param resourcePrefix string
param environmentAbbreviation string


// required for integration with the firewall policy created by MLZ
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-08-01' existing = {
  name: firewallPolicyName
}

// EXAMPLE CODE BELOW:
// define the rule collection group for application rules
// var appRuleCollectionGroup = {
//  properties: {
//    priority: 300
//    ruleCollections: [
//      {
//        name: 'AzureAuth'
//        priority: 110
//        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
//        action: {
//          type: 'Allow'
//        }
//        rules: [
//          {
//            name: 'msftauth'
//            ruleType: 'ApplicationRule'
//            protocols: [
//              {
//                protocolType: 'Https'
//                port: 443
//              }
//            ]
//            fqdnTags: []
//            webCategories: []
//            targetFqdns: [
//              'aadcdn.msftauth.net'
//              'aadcdn.msauth.net'
//            ]
//            targetUrls: []
//            terminateTLS: false
//            sourceAddresses: ['*']
//            destinationAddresses: []
//            sourceIpGroups: []
//          }
//        ]
//      }
//    ]
//  }
//}
//
//// Azure Firewall Policy Rule Collection Group for Application Rules
//resource appRuleCreate 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = if (environmentAbbreviation == 'prod') {
//  parent: firewallPolicy
//  name: '${resourcePrefix}-${environmentAbbreviation}-AppRuleCollectionGroup'
//  properties: appRuleCollectionGroup.properties
//}

// Azure Firewall Policy Rule Collection Group for Network Rules
// resource <Example: networkRuleCreate> 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
//  parent: firewallPolicy
//  name: '${resourcePrefix}-${environmentAbbreviation}-NetworkRuleCollectionGroup'
//  properties: neworksRuleCollectionGroup.properties
// dependsOn: [ appRuleCreate ]
//}

// Code below just retrieves the existing app rule firewall policy put in place by the default MLZ deployment.  
// This allows this module to be called by firewall.bicep with no use purpose
resource appRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' existing = {
  parent: firewallPolicy
  name: '${resourcePrefix}-${environmentAbbreviation}-AppRuleCollectionGroup'
}

output appRuleCollectionGroupId string = appRuleCollectionGroup.id
