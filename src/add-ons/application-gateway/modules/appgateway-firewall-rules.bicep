// appgateway-firewall-rules.bicep
// Deploys baseline (always) firewall policy rule collection group for Application Gateway required egress
// and any provided custom rule collection groups.

targetScope = 'resourceGroup'

@description('Firewall Policy resource ID to attach rule collection groups to.')
param firewallPolicyResourceId string
@description('Optional custom rule collection groups (array of objects with name/properties).')
param customRuleCollectionGroups array = []
@description('Priority for the baseline rule collection group (lower number = higher precedence).')
param baselinePriority int = 200
@description('Priority used for the platform service tags rule collection within the baseline group.')
param baselinePlatformCollectionPriority int = 100
@description('Priority used for the CRL/OCSP application rule collection within the baseline group.')
param baselineCrlOcspCollectionPriority int = 110

// Extract scope info
var fpName = last(split(firewallPolicyResourceId, '/'))

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-03-01' existing = {
  name: fpName
}

// Baseline required network rule collection (service tags) and application rule collection (OCSP/CRL)
resource appGwBaseline 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = {
  name: 'AppGw-Baseline'
  parent: firewallPolicy
  properties: {
    priority: baselinePriority
    ruleCollections: [
      {
        name: 'AllowPlatformServiceTags'
        priority: baselinePlatformCollectionPriority
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: { type: 'Allow' }
        rules: [
          {
            name: 'AllowAzureControlPlane443'
            ruleType: 'NetworkRule'
            ipProtocols: ['TCP']
            sourceAddresses: ['*']
            destinationAddresses: [
              // Service tags expressed here (service tags are allowed in destinationAddresses for Firewall Policy Network Rules)
              'AzureActiveDirectory'
              'AzureResourceManager'
              'AzureTrafficManager'
              'AzureMonitor'
              'Storage'
            ]
            destinationPorts: ['443']
            sourceIpGroups: []
            destinationIpGroups: []
            destinationFqdns: []
          }
        ]
      }
      {
        name: 'AllowCrlOcsp'
        priority: baselineCrlOcspCollectionPriority
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: { type: 'Allow' }
        rules: [
          {
            name: 'AllowCrlOcsp'
            ruleType: 'ApplicationRule'
            sourceAddresses: ['*']
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'ocsp.digicert.com'
              'crl3.digicert.com'
              'crl.microsoft.com'
            ]
          }
        ]
      }
    ]
  }
}

// Deploy custom groups (if any)
@batchSize(1)
resource appGwCustomRuleGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = [for (g, i) in customRuleCollectionGroups: {
  name: g.name
  parent: firewallPolicy
  properties: g.properties
}]

output baselineRuleCollectionGroupName string = appGwBaseline.name
output customRuleCollectionGroupNames array = [for (g, i) in customRuleCollectionGroups: appGwCustomRuleGroups[i].name]
