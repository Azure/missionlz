// appgateway-core.bicep - Multi-listener Application Gateway (Scenario A)

@description('Deployment location')
param location string
@description('Application Gateway resource name (from naming module)')
param appGatewayName string
@description('Public IP name (from naming module)')
param publicIpName string
@description('Subnet ID for the Application Gateway')
param subnetId string
@description('Global baseline WAF policy resource ID applied at gateway (listeners inherit if no override)')
param wafPolicyId string
@description('Tags object')
param tags object = {}
@description('User Assigned Identity resource ID for Key Vault access')
param userAssignedIdentityResourceId string

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
@description('Listeners (application configurations) array: objects { name, hostNames?, backendAddresses: [{ipAddress:"x.x.x.x"}|{fqdn:"host"}], backendPort?, backendProtocol?, healthProbePath?, probeInterval?, probeTimeout?, unhealthyThreshold?, certificateSecretId (Key Vault secret Id), wafPolicyId?, wafExclusions?[] } (All listeners share the single frontend public IP).')
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
      statusCodes: [ '200-399' ]
    }
  }
}]

var backendHttpSettingsCollection = [for l in listeners: {
  name: 'setting-${l.name}'
  properties: {
    port: l.backendPort ?? defaultBackendPort
    protocol: l.backendProtocol ?? defaultBackendProtocol
    pickHostNameFromBackendAddress: true
    cookieBasedAffinity: 'Disabled'
    requestTimeout: 30
    probe: {
      id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'probe-${l.name}')
    }
  }
}]

// (Removed global shared certificate; per-listener certs defined later)

// Per-listener generated WAF policies (only when wafExclusions provided & no explicit wafPolicyId)
resource perListenerWafPolicies 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = [for l in listeners: if (length(l.wafExclusions ?? []) > 0 && empty(l.wafPolicyId ?? '')) {
  name: 'agw-wafp-${l.name}'
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: generatedPolicyMode
      requestBodyCheck: generatedPolicyRequestBodyCheck
      maxRequestBodySizeInKb: generatedPolicyMaxRequestBodySizeInKb
      fileUploadLimitInMb: generatedPolicyFileUploadLimitInMb
    }
    customRules: []
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: replace(generatedPolicyManagedRuleSetVersion, 'OWASP_', '')
        }
      ]
      exclusions: l.wafExclusions
    }
  }
}]

var effectiveListenerWafPolicyIds = [for l in listeners: !empty(l.wafPolicyId ?? '') ? l.wafPolicyId : (length(l.wafExclusions ?? []) > 0 ? resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', 'agw-wafp-${l.name}') : '')]

// Certificates per listener (required)
var sslCertificates = [for l in listeners: {
  name: 'cert-${l.name}'
  properties: {
    keyVaultSecretId: l.certificateSecretId
  }
}]

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
      id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, 'cert-${l.name}')
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

// Public IP
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
output publicIpAddress string = appgwPublicIp.properties.ipAddress
output listenerNames array = [for l in httpListeners: l.name]
output backendPoolNames array = [for p in backendAddressPools: p.name]
output requestRoutingRuleNames array = [for r in requestRoutingRules: r.name]
