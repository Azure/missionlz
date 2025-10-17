// appgateway-firewall-rules.bicep
// Deploys baseline (always) firewall policy rule collection group for Application Gateway required egress
// and any provided custom rule collection groups.

targetScope = 'resourceGroup'

@description('Firewall Policy resource ID to attach rule collection groups to.')
param firewallPolicyResourceId string
@description('Optional custom rule collection groups (array of objects with name/properties).')
param customRuleCollectionGroups array = []
@description('Optional list of backend CIDR prefixes (private endpoint or backend subnets) that Application Gateway must reach via firewall.')
param backendPrefixes array = []
@description('Application Gateway subnet CIDR (source) for backend allow rule.')
param appGatewaySubnetPrefix string = ''
@description('Priority for the baseline rule collection group (lower number = higher precedence).')
param baselinePriority int = 200
@description('Priority used for the platform service tags rule collection within the baseline group.')
param baselinePlatformCollectionPriority int = 100
@description('Priority used for the CRL/OCSP application rule collection within the baseline group.')
param baselineCrlOcspCollectionPriority int = 110
@description('Destination ports to allow from Application Gateway to backend prefixes (can include single ports or ranges like 443-445). Only used if backendPrefixes and appGatewaySubnetPrefix are provided.')
param backendAllowPorts array = [ '443' ]
@description('Optional detailed mapping objects for per-prefix ports. Each element: { prefix: <cidr>, ports: ["443","8443-8444"] }. When supplied (non-empty) it supersedes the broad backendPrefixes/backendAllowPorts rule.')
param backendPrefixPortMaps array = []
@description('Optional per-app mapping objects where each element: { destinationPrefixes: [cidr...], ports: [port|range,...] }. Takes highest precedence when non-empty (one rule per app).')
param backendAppPortMaps array = []

// Extract scope info
var fpName = last(split(firewallPolicyResourceId, '/'))

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-03-01' existing = {
  name: fpName
}

// Build baseline collections first
var baselineRuleCollections = [
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
          // Service tags (destinationAddresses supports service tags in Firewall Policy network rules)
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

// Build per-app rules (highest precedence)
var appBackendRules = [for (m,i) in backendAppPortMaps: {
  name: 'AllowAppGwBackendApp${i}'
  ruleType: 'NetworkRule'
  ipProtocols: ['TCP']
  sourceAddresses: [appGatewaySubnetPrefix]
  destinationAddresses: m.destinationPrefixes
  destinationPorts: m.ports
  sourceIpGroups: []
  destinationIpGroups: []
  destinationFqdns: []
}]

// Build detailed per-prefix rules (secondary precedence)
var detailedBackendRules = [for (m,i) in backendPrefixPortMaps: {
  name: 'AllowAppGwBackend${i}'
  ruleType: 'NetworkRule'
  ipProtocols: ['TCP']
  sourceAddresses: [appGatewaySubnetPrefix]
  destinationAddresses: [m.prefix]
  destinationPorts: m.ports
  sourceIpGroups: []
  destinationIpGroups: []
  destinationFqdns: []
}]

// Fallback single broad rule if no detailed map
var fallbackBackendRule = (!empty(appGatewaySubnetPrefix) && length(backendPrefixes) > 0 && length(backendAllowPorts) > 0) ? [{
  name: 'AllowAppGwBackend443'
  ruleType: 'NetworkRule'
  ipProtocols: ['TCP']
  sourceAddresses: [appGatewaySubnetPrefix]
  destinationAddresses: backendPrefixes
  destinationPorts: backendAllowPorts
  sourceIpGroups: []
  destinationIpGroups: []
  destinationFqdns: []
}] : []

var backendAllowCollection = (!empty(appGatewaySubnetPrefix) && (length(appBackendRules) > 0 || length(detailedBackendRules) > 0 || length(fallbackBackendRule) > 0)) ? [
  {
    name: 'AllowAppGwToBackends'
    // After platform tags collection
    priority: baselinePlatformCollectionPriority + 1
    ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
    action: { type: 'Allow' }
    rules: length(appBackendRules) > 0 ? appBackendRules : (length(detailedBackendRules) > 0 ? detailedBackendRules : fallbackBackendRule)
  }
] : []

// Baseline required network & application rule collections (plus conditional backend allow)
resource appGwBaseline 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-03-01' = {
  name: 'AppGw-Baseline'
  parent: firewallPolicy
  properties: {
    priority: baselinePriority
    ruleCollections: concat(baselineRuleCollections, backendAllowCollection)
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
