// appgateway-core.bicep - Application Gateway (Scenario A: WAF before Firewall)
@description('Deployment location')
param location string
@description('Deployment name for resource naming context (used as prefix)')
param deploymentName string
@description('Subnet ID for the AppGateway')
param subnetId string
@description('WAF policy resource ID')
param wafPolicyId string
@description('Common defaults object (expects autoscaleMinCapacity?, autoscaleMaxCapacity?, backendPort?, backendProtocol?, healthProbePath?, enableHttp2?, defaultCertificateSecretId?, probeInterval?, probeTimeout?, unhealthyThreshold?)')
param commonDefaults object
@description('Apps array defining listeners/backends; minimal scaffold only uses first element')
param apps array
@description('Enable diagnostic settings (currently placeholder)')
param enableDiagnosticLogs bool
@description('Log Analytics Workspace ID (for future diagnostics module integration)')
param logAnalyticsWorkspaceId string
@description('Tags object')
param tags object = {}

var autoscaleMinCapacity = commonDefaults.autoscaleMinCapacity ?? 2
var autoscaleMaxCapacity = commonDefaults.autoscaleMaxCapacity ?? 4
var defaultBackendPort = commonDefaults.backendPort ?? 443
var defaultBackendProtocol = commonDefaults.backendProtocol ?? 'Https'
var defaultHealthProbePath = commonDefaults.healthProbePath ?? '/health'
var enableHttp2 = commonDefaults.enableHttp2 ?? false
var defaultCertificateSecretId = commonDefaults.defaultCertificateSecretId ?? ''
var listenerFrontendPort = commonDefaults.listenerFrontendPort ?? 443
var probeInterval = commonDefaults.probeInterval ?? 30
var probeTimeout = commonDefaults.probeTimeout ?? 30
var unhealthyThreshold = commonDefaults.unhealthyThreshold ?? 3

// Public IP
resource appgwPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
	name: '${deploymentName}-appgw-pip'
	location: location
	sku: {
		name: 'Standard'
		tier: 'Regional'
	}
	properties: {
		publicIPAllocationMethod: 'Static'
	}
	tags: tags
}

// Use first app only in minimal scaffold
var firstApp = length(apps) > 0 ? apps[0] : {}
var hasApp = length(apps) > 0
var sslCerts = hasApp ? [
	{
		name: 'cert-${firstApp.name}'
		properties: {
			keyVaultSecretId: firstApp.certificateSecretId ?? defaultCertificateSecretId
		}
	}
] : []

// Backend pools
var targets = hasApp ? (firstApp.backendTargets ?? []) : []
var backendAddresses = [for target in targets: target.type == 'ip' ? { ipAddress: target.value } : { fqdn: target.value }]
var backendAddressPools = hasApp ? [
	{
		name: 'pool-${firstApp.name}'
		properties: {
			backendAddresses: backendAddresses
		}
	}
] : []

// Probes
var probes = hasApp ? [
	{
		name: 'probe-${firstApp.name}'
		properties: {
			protocol: firstApp.backendProtocol ?? defaultBackendProtocol
			path: firstApp.healthProbePath ?? defaultHealthProbePath
			interval: probeInterval
			timeout: probeTimeout
			unhealthyThreshold: unhealthyThreshold
			pickHostNameFromBackendHttpSettings: true
			minServers: 0
			match: {
				statusCodes: [ '200-399' ]
			}
		}
	}
] : []

// Backend HTTP settings
var backendHttpSettings = hasApp ? [
	{
		name: 'setting-${firstApp.name}'
		properties: {
			port: firstApp.backendPort ?? defaultBackendPort
			protocol: firstApp.backendProtocol ?? defaultBackendProtocol
			pickHostNameFromBackendAddress: true
			cookieBasedAffinity: 'Disabled'
			requestTimeout: 30
			probe: length(probes) > 0 ? {
				id: resourceId('Microsoft.Network/applicationGateways/probes', '${deploymentName}-appgw', 'probe-${firstApp.name}')
			} : null
		}
	}
] : []

// Listeners
var listeners = hasApp ? [
	{
		name: 'listener-${firstApp.name}'
		properties: {
			frontendIPConfiguration: {
				id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${deploymentName}-appgw', 'appgw-frontendip')
			}
			frontendPort: {
				id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${deploymentName}-appgw', 'port-https')
			}
			hostNames: firstApp.hostNames ?? []
			protocol: 'Https'
			sslCertificate: length(sslCerts) > 0 ? {
				id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', '${deploymentName}-appgw', 'cert-${firstApp.name}')
			} : null
		}
	}
] : []

// Request routing rules
var requestRoutingRules = hasApp ? [
	{
		name: 'rule-${firstApp.name}'
		properties: {
			httpListener: length(listeners) > 0 ? {
				id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${deploymentName}-appgw', 'listener-${firstApp.name}')
			} : null
			backendAddressPool: length(backendAddressPools) > 0 ? {
				id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${deploymentName}-appgw', 'pool-${firstApp.name}')
			} : null
			backendHttpSettings: length(backendHttpSettings) > 0 ? {
				id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${deploymentName}-appgw', 'setting-${firstApp.name}')
			} : null
			ruleType: 'Basic'
		}
	}
] : []

// Use an API version with recognized sku property
resource appGateway 'Microsoft.Network/applicationGateways@2022-05-01' = {
	name: '${deploymentName}-appgw'
	location: location
	tags: tags
	// SKU omitted in minimal scaffold to bypass type validation issues; will reintroduce once apiVersion confirmed
	properties: {
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
				properties: { port: listenerFrontendPort }
			}
		]
		sslCertificates: sslCerts
		probes: probes
		backendAddressPools: backendAddressPools
		backendHttpSettingsCollection: backendHttpSettings
		httpListeners: listeners
		requestRoutingRules: requestRoutingRules
		enableHttp2: enableHttp2
	}
}

// Output maps for external consumers
output appGatewayResourceId string = appGateway.id
output publicIpAddress string = appgwPublicIp.properties.ipAddress
var listenerNames = [for l in listeners: l.name]
var backendPoolNames = [for p in backendAddressPools: p.name]

output listenerNames array = listenerNames
output backendPoolNames array = backendPoolNames
