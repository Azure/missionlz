// appgateway-core.bicep - Multi-listener Application Gateway (Scenario A)

@description('Deployment location')
param location string
@description('Application Gateway resource name (from naming module)')
param appGatewayName string
@description('Public IP resource name (from naming module).')
param publicIpName string
@description('Subnet ID for the Application Gateway')
param subnetId string
@description('Global baseline WAF policy resource ID applied at gateway (listeners inherit if no override)')
param wafPolicyId string
@description('Tags object')
param tags object = {}
@description('User Assigned Identity resource ID for Key Vault access')
param userAssignedIdentityResourceId string
@description('Base WAF policy name from naming convention (used to derive per-listener policy names).')
param baseWafPolicyName string

// Baseline backend & probe defaults
@description('Default backend port when a listener object omits backendPort')
param defaultBackendPort int = 443
@description('Default backend protocol (Https or Http) when listener omits backendProtocol')
param defaultBackendProtocol string = 'Https'
@description('Default health probe path when listener omits healthProbePath')
param defaultHealthProbePath string = '/'
@description('Default probe interval seconds when listener omits probeInterval')
param defaultProbeInterval int = 30
@description('Default probe timeout seconds when listener omits probeTimeout')
param defaultProbeTimeout int = 30
@description('Default unhealthy threshold when listener omits unhealthyThreshold')
param defaultUnhealthyThreshold int = 3
@description('Default acceptable backend probe HTTP status code ranges or discrete codes (array). Example: [ "200-399", "403" ]')
param defaultProbeMatchStatusCodes array = [ '200-399' ]

// Baseline WAF policy settings used ONLY when generating per-listener policies from exclusions
@description('Generated per-listener WAF policy mode (Detection or Prevention)')
param generatedPolicyMode string = 'Prevention'
@description('Generated per-listener WAF policy requestBodyCheck')
param generatedPolicyRequestBodyCheck bool = true
@description('Generated per-listener WAF policy max request body size KB')
param generatedPolicyMaxRequestBodySizeInKb int = 128
@description('Generated per-listener WAF policy file upload limit MB')
param generatedPolicyFileUploadLimitInMb int = 100
@description('Generated per-listener WAF managed rule set version (e.g. 3.2)')
param generatedPolicyManagedRuleSetVersion string = '3.2'

// Listener definitions
@description('Listeners (application configurations) array: objects { name, hostNames?, backendAddresses: [{ipAddress|fqdn}], backendPort?, backendProtocol?, healthProbePath?, probeInterval?, probeTimeout?, unhealthyThreshold?, certificateSecretId, wafPolicyId?, wafExclusions?[], wafOverrides?: { mode?, requestBodyCheck?, maxRequestBodySizeInKb?, fileUploadLimitInMb?, managedRuleSetVersion?, ruleGroupOverrides?, exclusions? } }')
param listeners array

// Each listener must now specify its own certificate secret Id (certificateSecretId) so no global certificate parameter is required.

// Platform settings
@description('Frontend port for HTTPS listeners')
param httpsListenerPort int = 443
@description('Enable HTTP2 on gateway')
param enableHttp2 bool = true
@description('Autoscale minimum capacity')
param autoscaleMinCapacity int = 1
@description('Autoscale maximum capacity')
param autoscaleMaxCapacity int = 2

// Derived collections (avoid nested for in object properties)
var backendAddressPools = [for l in listeners: {
  name: 'pool-${l.name}'
  properties: {
    backendAddresses: l.backendAddresses ?? []
  }
}]

var probes = [for l in listeners: {
  name: 'probe-${l.name}'
  properties: {
    protocol: l.backendProtocol ?? defaultBackendProtocol
    path: l.healthProbePath ?? defaultHealthProbePath
    interval: l.probeInterval ?? defaultProbeInterval
    timeout: l.probeTimeout ?? defaultProbeTimeout
    unhealthyThreshold: l.unhealthyThreshold ?? defaultUnhealthyThreshold
    pickHostNameFromBackendHttpSettings: true
    minServers: 0
    match: {
      // Use per-listener override if provided, else fall back to defaultProbeMatchStatusCodes
      statusCodes: length(l.probeMatchStatusCodes ?? []) > 0 ? l.probeMatchStatusCodes : defaultProbeMatchStatusCodes
    }
  }
}]

var backendHttpSettingsCollection = [for l in listeners: {
  name: 'setting-${l.name}'
  properties: {
    port: l.backendPort ?? defaultBackendPort
    protocol: l.backendProtocol ?? defaultBackendProtocol
    // If caller supplies backendHostHeader use hostName override; else derive from backend address
    pickHostNameFromBackendAddress: empty(l.backendHostHeader ?? '')
    hostName: !empty(l.backendHostHeader ?? '') ? l.backendHostHeader : null
    cookieBasedAffinity: 'Disabled'
    requestTimeout: 30
    probe: {
      id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'probe-${l.name}')
    }
  }
}]

// (Removed global shared certificate; per-listener certs defined later)

// Per-listener WAF policies
// Created when either (a) wafExclusions supplied OR (b) wafOverrides object present AND no explicit wafPolicyId provided.
// For any required WAF policy setting not specified inside wafOverrides, the value falls back to the baseline ("generated"*) parameters
// passed into this module (which should mirror the global / baseline WAF policy). This satisfies the requirement that undefined
// properties inherit baseline values instead of arbitrary constants.
resource perListenerWafPolicies 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = [for l in listeners: if ((length(l.wafExclusions ?? []) > 0 || !empty(l.wafOverrides)) && empty(l.wafPolicyId ?? '')) {
  // Derive per-listener WAF policy name: <base>-<listener>-<hash>-waf (trim to 80 chars)
  // Hash is first 5 chars of uniqueString(resourceGroup().id, baseWafPolicyName, listenerName) for deterministic uniqueness.
  name: substring('${baseWafPolicyName}-${l.name}-${substring(uniqueString(resourceGroup().id, baseWafPolicyName, l.name),0,5)}-waf', 0, min(80, length('${baseWafPolicyName}-${l.name}-${substring(uniqueString(resourceGroup().id, baseWafPolicyName, l.name),0,5)}-waf')))
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
  mode: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'mode')) ? l.wafOverrides.mode : generatedPolicyMode
  requestBodyCheck: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'requestBodyCheck')) ? l.wafOverrides.requestBodyCheck : generatedPolicyRequestBodyCheck
  maxRequestBodySizeInKb: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'maxRequestBodySizeInKb')) ? l.wafOverrides.maxRequestBodySizeInKb : generatedPolicyMaxRequestBodySizeInKb
  fileUploadLimitInMb: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'fileUploadLimitInMb')) ? l.wafOverrides.fileUploadLimitInMb : generatedPolicyFileUploadLimitInMb
    }
    customRules: []
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: replace((!empty(l.wafOverrides) && contains(l.wafOverrides,'managedRuleSetVersion')) ? l.wafOverrides.managedRuleSetVersion : generatedPolicyManagedRuleSetVersion, 'OWASP_', '')
          // Pass-through advanced overrides if provided (shape must match ARM schema):
          // l.wafOverrides.ruleGroupOverrides: [ { ruleGroupName: 'REQUEST-930-APPLICATION-ATTACK-LFI', rules: [ { ruleId: '930100', state: 'Disabled' } ] } ]
          ruleGroupOverrides: (!empty(l.wafOverrides) && contains(l.wafOverrides,'ruleGroupOverrides')) ? l.wafOverrides.ruleGroupOverrides : []
        }
      ]
  // Merge exclusions if wafOverrides.exclusions present
  exclusions: (!empty(l.wafOverrides) && contains(l.wafOverrides,'exclusions') && length(l.wafOverrides.exclusions) > 0) ? union(l.wafExclusions ?? [], l.wafOverrides.exclusions) : l.wafExclusions
    }
  }
}]

var effectiveListenerWafPolicyIds = [for l in listeners: !empty(l.wafPolicyId ?? '') ? l.wafPolicyId : (length(l.wafExclusions ?? []) > 0 ? resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', 'agw-wafp-${l.name}') : '')]

// Certificate deduplication: one sslCertificate resource per unique non-empty Key Vault secret ID.
var allSecretIds = [for l in listeners: l.certificateSecretId]
// Keep only first occurrence of each non-empty secret ID, mark others empty then strip.
// Unique secrets at their first occurrence positions (duplicates/null replaced with null)
// Dedup (explicit for first three distinct secrets to avoid unsupported filter syntax in current Bicep version)
var secret0 = length(allSecretIds) > 0 ? allSecretIds[0] : ''
var secret1Raw = length(allSecretIds) > 1 ? allSecretIds[1] : ''
var secret1 = (!empty(secret1Raw) && secret1Raw != secret0) ? secret1Raw : ''
var secret2Raw = length(allSecretIds) > 2 ? allSecretIds[2] : ''
var secret2 = (!empty(secret2Raw) && secret2Raw != secret0 && secret2Raw != secret1Raw) ? secret2Raw : ''

var sslCertA = !empty(secret0) ? [ { name: 'cert-sh0', properties: { keyVaultSecretId: secret0 } } ] : []
var sslCertB = !empty(secret1) ? [ { name: 'cert-sh1', properties: { keyVaultSecretId: secret1 } } ] : []
var sslCertC = !empty(secret2) ? [ { name: 'cert-sh2', properties: { keyVaultSecretId: secret2 } } ] : []

var sslCertificates = union(sslCertA, union(sslCertB, sslCertC))

// Map listeners to certificate names
var listenerCertNames = [for l in listeners: !empty(l.certificateSecretId) && l.certificateSecretId == secret0 ? 'cert-sh0' : (!empty(l.certificateSecretId) && l.certificateSecretId == secret1 ? 'cert-sh1' : (!empty(l.certificateSecretId) && l.certificateSecretId == secret2 ? 'cert-sh2' : ''))]

// HTTPS listeners
var httpsListeners = [for (l,i) in listeners: {
  name: 'listener-${l.name}'
  properties: {
    frontendIPConfiguration: {
      id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appgw-frontendip')
    }
    frontendPort: {
      id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port-https')
    }
    hostNames: l.hostNames ?? []
    protocol: 'Https'
    sslCertificate: {
      id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, listenerCertNames[i])
    }
    firewallPolicy: !empty(effectiveListenerWafPolicyIds[i]) ? {
      id: effectiveListenerWafPolicyIds[i]
    } : null
  }
}]


// HTTPS routing rules
var httpsRequestRoutingRules = [for (l,i) in listeners: {
  name: 'rule-${l.name}'
  properties: {
    httpListener: {
      id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'listener-${l.name}')
    }
    backendAddressPool: {
      id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'pool-${l.name}')
    }
    backendHttpSettings: {
      id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'setting-${l.name}')
    }
    ruleType: 'Basic'
    priority: 100 + (i * 10)
  }
}]

// Combined (HTTPS only; HTTP->HTTPS redirect deferred)
var httpListeners = httpsListeners
var requestRoutingRules = httpsRequestRoutingRules

// Public IP (single)
resource appgwPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: publicIpName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// Application Gateway
resource appGateway 'Microsoft.Network/applicationGateways@2021-08-01' = {
  name: appGatewayName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    firewallPolicy: {
      id: wafPolicyId
    }
    autoscaleConfiguration: {
      minCapacity: autoscaleMinCapacity
      maxCapacity: autoscaleMaxCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appgw-gatewayipconfig'
        properties: {
          subnet: { id: subnetId }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-frontendip'
        properties: {
          publicIPAddress: { id: appgwPublicIp.id }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-https'
        properties: { port: httpsListenerPort }
      }
    ]
    sslCertificates: sslCertificates
    backendAddressPools: backendAddressPools
    probes: probes
    backendHttpSettingsCollection: backendHttpSettingsCollection
    httpListeners: httpListeners
    requestRoutingRules: requestRoutingRules
    enableHttp2: enableHttp2
  }
}

// Outputs
output appGatewayResourceId string = appGateway.id
// Outputs: first public IP (back-compat) and full set
output publicIpAddress string = appgwPublicIp.properties.ipAddress
output listenerNames array = [for l in httpListeners: l.name]
output backendPoolNames array = [for p in backendAddressPools: p.name]
output requestRoutingRuleNames array = [for r in requestRoutingRules: r.name]
