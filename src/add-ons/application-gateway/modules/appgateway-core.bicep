// moved from root: appgateway-core.bicep
param location string
param appGatewayName string
param publicIpName string
param subnetId string
param wafPolicyId string
param tags object = {}
param userAssignedIdentityResourceId string
param baseWafPolicyName string
param defaultBackendPort int = 443
@allowed(['Https','Http'])
param defaultBackendProtocol string = 'Https'
param defaultHealthProbePath string = '/'
param defaultProbeInterval int = 30
param defaultProbeTimeout int = 30
param defaultUnhealthyThreshold int = 3
param defaultProbeMatchStatusCodes array = [ '200-399' ]
@allowed(['Prevention','Detection'])
param generatedPolicyMode string = 'Prevention'
param generatedPolicyRequestBodyCheck bool = true
param generatedPolicyMaxRequestBodySizeInKb int = 128
param generatedPolicyFileUploadLimitInMb int = 100
param generatedPolicyManagedRuleSetVersion string = '3.2'
param listeners array
param httpsListenerPort int = 443
param enableHttp2 bool = true
param autoscaleMinCapacity int = 1
param autoscaleMaxCapacity int = 2
var backendAddressPools = [for l in listeners: { name: 'pool-${l.name}', properties: { backendAddresses: l.backendAddresses ?? [] } }]
var probes = [for l in listeners: { name: 'probe-${l.name}', properties: { protocol: l.backendProtocol ?? defaultBackendProtocol, path: l.healthProbePath ?? defaultHealthProbePath, interval: l.probeInterval ?? defaultProbeInterval, timeout: l.probeTimeout ?? defaultProbeTimeout, unhealthyThreshold: l.unhealthyThreshold ?? defaultUnhealthyThreshold, pickHostNameFromBackendHttpSettings: true, minServers: 0, match: { statusCodes: length(l.probeMatchStatusCodes ?? []) > 0 ? l.probeMatchStatusCodes : defaultProbeMatchStatusCodes } } }]
var backendHttpSettingsCollection = [for l in listeners: { name: 'setting-${l.name}', properties: { port: l.backendPort ?? defaultBackendPort, protocol: l.backendProtocol ?? defaultBackendProtocol, pickHostNameFromBackendAddress: empty(l.backendHostHeader ?? ''), hostName: !empty(l.backendHostHeader ?? '') ? l.backendHostHeader : null, cookieBasedAffinity: 'Disabled', requestTimeout: 30, probe: { id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'probe-${l.name}') } } }]
var _generatedPerListenerPolicyNames = [for l in listeners: substring('${baseWafPolicyName}-${l.name}-${substring(uniqueString(resourceGroup().id, baseWafPolicyName, l.name),0,5)}-waf', 0, min(80, length('${baseWafPolicyName}-${l.name}-${substring(uniqueString(resourceGroup().id, baseWafPolicyName, l.name),0,5)}-waf')))]
resource perListenerWafPolicies 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = [for (l,idx) in listeners: if ((length(l.wafExclusions ?? []) > 0 || !empty(l.wafOverrides)) && empty(l.wafPolicyId ?? '')) { name: _generatedPerListenerPolicyNames[idx], location: location, properties: { policySettings: { state: 'Enabled', mode: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'mode')) ? l.wafOverrides.mode : generatedPolicyMode, requestBodyCheck: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'requestBodyCheck')) ? l.wafOverrides.requestBodyCheck : generatedPolicyRequestBodyCheck, maxRequestBodySizeInKb: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'maxRequestBodySizeInKb')) ? l.wafOverrides.maxRequestBodySizeInKb : generatedPolicyMaxRequestBodySizeInKb, fileUploadLimitInMb: (!empty(l.wafOverrides) && contains(l.wafOverrides, 'fileUploadLimitInMb')) ? l.wafOverrides.fileUploadLimitInMb : generatedPolicyFileUploadLimitInMb }, customRules: [], managedRules: { managedRuleSets: [ { ruleSetType: 'OWASP', ruleSetVersion: replace((!empty(l.wafOverrides) && contains(l.wafOverrides,'managedRuleSetVersion')) ? l.wafOverrides.managedRuleSetVersion : generatedPolicyManagedRuleSetVersion, 'OWASP_', ''), ruleGroupOverrides: (!empty(l.wafOverrides) && contains(l.wafOverrides,'ruleGroupOverrides')) ? l.wafOverrides.ruleGroupOverrides : [] } ], exclusions: (!empty(l.wafOverrides) && contains(l.wafOverrides,'exclusions') && length(l.wafOverrides.exclusions) > 0) ? union(l.wafExclusions ?? [], l.wafOverrides.exclusions) : l.wafExclusions } } }]
var allSecretIds = [for l in listeners: l.certificateSecretId]
var distinctSecretIds = [for (s,i) in allSecretIds: (!empty(s) && indexOf(allSecretIds, s) == i) ? s : '']
var filteredSecretIds = [for s in distinctSecretIds: !empty(s) ? s : null]
var sslCertificates = [for (s,i) in filteredSecretIds: { name: 'cert-sh${i}', properties: { keyVaultSecretId: s } }]
var listenerCertNames = [for l in listeners: 'cert-sh${indexOf(filteredSecretIds, l.certificateSecretId)}']
// Listener construction: attach certificate, hostnames, and decide WAF policy reference order of precedence:
// 1. Explicit listener-level wafPolicyId provided in apps[] entry
// 2. Generated per-listener policy when overrides or exclusions exist
// 3. (None) -> falls back to global gateway-level firewallPolicy
var httpsListeners = [for (l,i) in listeners: {
	name: 'listener-${l.name}'
	properties: {
		frontendIPConfiguration: { id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appgw-frontendip') }
		frontendPort: { id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port-https') }
		hostNames: l.hostNames ?? []
		protocol: 'Https'
		sslCertificate: { id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, listenerCertNames[i]) }
		firewallPolicy: !empty(l.wafPolicyId ?? '') ? { id: l.wafPolicyId } : ((length(l.wafExclusions ?? []) > 0 || !empty(l.wafOverrides)) ? { id: perListenerWafPolicies[i].id } : null)
	}
}]
var httpsRequestRoutingRules = [for (l,i) in listeners: { name: 'rule-${l.name}', properties: { httpListener: { id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'listener-${l.name}') }, backendAddressPool: { id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'pool-${l.name}') }, backendHttpSettings: { id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'setting-${l.name}') }, ruleType: 'Basic', priority: 100 + (i * 10) } }]
resource appgwPublicIp 'Microsoft.Network/publicIPAddresses@2022-07-01' = { name: publicIpName, location: location, sku: { name: 'Standard' }, properties: { publicIPAllocationMethod: 'Static' } }
// Omit firewallPolicy property if wafPolicyId empty (defensive; resolver guarantees non-empty unless user supplied empty existing ID)
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
		// Only include firewallPolicy when we have an ID
		firewallPolicy: !empty(wafPolicyId) ? {
			id: wafPolicyId
		} : null
		autoscaleConfiguration: {
			minCapacity: autoscaleMinCapacity
			maxCapacity: autoscaleMaxCapacity
		}
		gatewayIPConfigurations: [
			{
				name: 'appgw-gatewayipconfig'
				properties: {
					subnet: {
						id: subnetId
					}
				}
			}
		]
		frontendIPConfigurations: [
			{
				name: 'appgw-frontendip'
				properties: {
					publicIPAddress: {
						id: appgwPublicIp.id
					}
				}
			}
		]
		frontendPorts: [
			{
				name: 'port-https'
				properties: {
					port: httpsListenerPort
				}
			}
		]
		sslCertificates: sslCertificates
		backendAddressPools: backendAddressPools
		probes: probes
		backendHttpSettingsCollection: backendHttpSettingsCollection
		httpListeners: httpsListeners
		requestRoutingRules: httpsRequestRoutingRules
		enableHttp2: enableHttp2
	}
}
output appGatewayResourceId string = appGateway.id
output publicIpAddress string = appgwPublicIp.properties.ipAddress
output listenerNames array = [for l in httpsListeners: l.name]
output backendPoolNames array = [for p in backendAddressPools: p.name]
output requestRoutingRuleNames array = [for r in httpsRequestRoutingRules: r.name]
output generatedPerListenerWafPolicyIds array = [for (l,i) in listeners: (!empty(l.wafPolicyId ?? '')) ? '' : ((length(l.wafExclusions ?? []) > 0 || !empty(l.wafOverrides)) ? perListenerWafPolicies[i].id : '')]
output effectivePerListenerWafPolicyIds array = [for (l,i) in listeners: !empty(l.wafPolicyId ?? '') ? l.wafPolicyId : ((length(l.wafExclusions ?? []) > 0 || !empty(l.wafOverrides)) ? perListenerWafPolicies[i].id : '')]
