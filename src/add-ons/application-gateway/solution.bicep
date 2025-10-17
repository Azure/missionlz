// solution.bicep - Orchestrates Scenario A Application Gateway WAF_v2 before Firewall
// NOTE: Initial scaffold; resources not fully implemented yet.
targetScope = 'subscription'

@description('Azure region for deployment')
param location string
@description('A suffix to use for uniquely naming deployment-scoped modules (not part of resource names).')
param deploymentNameSuffix string = utcNow()
@description('Hub VNet resource ID where AppGateway subnet will reside')
param hubVnetResourceId string
// Extract hub resource group name early for later parameter defaults
var hubRgName = split(hubVnetResourceId, '/')[4]
@description('Address prefix for the dedicated Application Gateway subnet (must be within hub VNet and unused). Platform recommendation for WAF_v2 is /24 for maximum future autoscale headroom; minimum supported is /26. Using /26 here by design to conserve address space.')
param appGatewaySubnetAddressPrefix string = '10.0.129.0/26'
@description('Subnet name for the Application Gateway.')
param appGatewaySubnetName string = 'AppGateway'
@description('Disable private endpoint network policies on the AppGateway subnet (prevents Private Endpoint creation there).')
param disablePrivateEndpointNetworkPolicies bool = true
@description('Common default settings object applied to each app unless overridden')
param commonDefaults object
@description('Array of application definitions. Each app: { name, backendAddresses:[{ipAddress|fqdn}], certificateSecretId, (optional) addressPrefix, (optional) addressPrefixes:[CIDR...], (optional) wafOverrides:{ mode, requestBodyCheck, maxRequestBodySizeInKb, fileUploadLimitInMb, managedRuleSetVersion } }. addressPrefixes overrides addressPrefix when provided.')
param apps array

@description('Tags to apply to all created resources')
param tags object = {}
@description('Existing WAF policy resource ID (if provided, skip creating new policy)')
param existingWafPolicyId string = ''
@description('Whether to create and associate an NSG to the App Gateway subnet.')
param createSubnetNsg bool = true
@description('Optional custom firewall rule collection groups for App Gateway egress. If empty, an opinionated default group will be created.')
param customAppGatewayFirewallRuleCollectionGroups array = []
@description('Destination ports to allow from Application Gateway subnet to backend prefixes (array of strings, supports ranges e.g. 443-445).')
param backendAllowPorts array = [ '443' ]
@description('Internal: future manual override for per-prefix port maps (leave empty).')
param backendPrefixPortMaps array = []
@description('Derived per-listener backend port maps (do not set manually).')
param backendAppPortMaps array = []
@description('Delimiter used in MLZ naming convention (pass through from core).')
param delimiter string = '-'
@description('Identifier / environment / location tokens used for naming; if not provided they will be inferred from hub VNet name when possible.')
param identifier string = ''
param environmentAbbreviation string = ''
param locationAbbreviation string = ''
@description('Network name token for naming (e.g. hub). If not provided inferred from hub VNet name segmentation.')
param networkName string = 'hub'
@description('Resource abbreviations object from core deployment (passed through from MLZ core).')
param resourceAbbreviations object
@description('Existing User Assigned Identity resource ID granting Key Vault secret get access for TLS certs (required).')
param userAssignedIdentityResourceId string
@description('Whether to create a Key Vault secrets read role assignment for the user-assigned identity (RBAC-enabled vault).')
param createKeyVaultSecretAccessRole bool = true
@description('Optional override for Key Vault resource group (defaults to hub RG).')
param keyVaultResourceGroupName string = ''
@description('Enable diagnostics (Log Analytics) for the Application Gateway')
param enableDiagnostics bool = true
@description('Existing Log Analytics Workspace resource ID used for diagnostics (leave empty to skip).')
param logAnalyticsWorkspaceResourceId string = ''

// WAF policy tuning (applies only when creating a new policy via resolver)
@description('Desired WAF policy mode when creating new policy (Prevention or Detection).')
@allowed([
  'Prevention'
  'Detection'
])
param wafPolicyMode string = 'Prevention'
@description('OWASP Core Rule Set version (e.g. 3.2, 3.1).')
param wafManagedRuleSetVersion string = '3.2'
@description('Enable or disable WAF requestBodyCheck when creating policy.')
param wafRequestBodyCheck bool = true
@description('Optional max request body size (KB) when creating new WAF policy.')
param wafMaxRequestBodySizeInKb int = 128
@description('Optional file upload limit (MB) when creating new WAF policy.')
param wafFileUploadLimitInMb int = 100

// Derive Key Vault name from first available certificate secret Id (default or first app) so we can assign RBAC role automatically
// Secret ID format: https://{vaultname}.vault.* /secrets/{secret}/{version}
var baseSecretId = (contains(commonDefaults, 'defaultCertificateSecretId') && !empty(commonDefaults.defaultCertificateSecretId)) ? commonDefaults.defaultCertificateSecretId : (!empty(apps) ? apps[0].certificateSecretId : '')
// Extract vault name robustly: split on '//' then take host, then take first segment before '.vault'
var keyVaultHost = !empty(baseSecretId) ? split(split(baseSecretId, '//')[1], '/')[0] : ''
var keyVaultName = !empty(keyVaultHost) ? substring(keyVaultHost, 0, indexOf(keyVaultHost, '.vault')) : ''
var keyVaultRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User

var effectiveKeyVaultRg = empty(keyVaultResourceGroupName) ? hubRgName : keyVaultResourceGroupName
// (Removed inline existing Key Vault reference; handled inside kv-role-assignment module)

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: last(split(userAssignedIdentityResourceId, '/'))
  scope: resourceGroup(hubRgName)
}

// Role assignment giving the user-assigned identity access to read secrets from the Key Vault (RBAC mode)
// Least privilege: scope role assignment directly to the Key Vault instead of subscription
module kvSecretsReader 'modules/kv-role-assignment.bicep' = if (createKeyVaultSecretAccessRole && !empty(keyVaultName)) {
  name: 'kvSecretsReader'
  scope: resourceGroup(effectiveKeyVaultRg)
  params: {
    keyVaultName: keyVaultName
    roleDefinitionId: keyVaultRoleDefinitionId
  principalId: uai.properties.principalId
  userAssignedIdentityResourceId: userAssignedIdentityResourceId
    enable: true
  }
}

// Intentional exclusion: no default 0.0.0.0/0 forced route (selective routing only).

// Ensure subnet
// (Reordered modules per Option A: create NSG (optional) & route table BEFORE subnet so we can associate in single definition)

// Derive naming tokens from hub VNet name if not explicitly provided
var hubVnetName = last(split(hubVnetResourceId, '/'))
var inferredTokens = split(hubVnetName, delimiter)
var effectiveIdentifier = empty(identifier) && length(inferredTokens) > 0 ? inferredTokens[0] : identifier
var effectiveEnvironment = empty(environmentAbbreviation) && length(inferredTokens) > 1 ? inferredTokens[1] : environmentAbbreviation
var effectiveLocationAbbrev = empty(locationAbbreviation) && length(inferredTokens) > 2 ? inferredTokens[2] : locationAbbreviation

// Naming convention module (subscription scope)
module naming '../../modules/naming-convention.bicep' = {
  name: 'naming-appgw-${deploymentNameSuffix}'
  params: {
    delimiter: delimiter
    identifier: effectiveIdentifier
    environmentAbbreviation: effectiveEnvironment
    locationAbbreviation: effectiveLocationAbbrev
    networkName: networkName
    resourceAbbreviations: resourceAbbreviations
  }
}

// Resolve firewall private IP via RG-scoped helper (avoids direct runtime property access in subscription scope)
module resolveFirewallIp 'modules/resolve-firewall-ip.bicep' = {
  name: 'resolveFirewallIp'
  scope: resourceGroup(hubRgName)
  params: {
    firewallName: naming.outputs.names.azureFirewall
  }
}
var firewallPrivateIp = resolveFirewallIp.outputs.privateIpAddress
var firewallPolicyResourceId = resourceId(subscription().subscriptionId, hubRgName, 'Microsoft.Network/firewallPolicies', naming.outputs.names.azureFirewallPolicy)

// Route table prefix derivation (multi-prefix, no validation). Fallback to prefix-derived label due to Bicep nested for limitations.
// Gather & deduplicate backend CIDR prefixes (apps[].addressPrefixes supersedes legacy addressPrefix)
var _appsPrefixMatrix = [for a in apps: (!empty(a.?addressPrefixes)) ? a.addressPrefixes : (!empty(a.?addressPrefix) ? [a.addressPrefix] : [])]
var allAppPrefixes = flatten(_appsPrefixMatrix)
var dedupPrefixes = [for (p,i) in allAppPrefixes: (!empty(p) && indexOf(allAppPrefixes,p) == i) ? p : '']
// Simplified: rely on explicit backendPrefixPortMaps parameter for per-app custom port mappings.
// If empty, module will fall back to broad rule using backendPrefixes + backendAllowPorts.
// Build forced route entries; original comprehension produced null placeholders. We use a ternary and then discard nulls via a second flattening step.
var effectiveInternalForcedRouteEntries = [for p in dedupPrefixes: !empty(p) ? {
  prefix: p
  source: replace(replace(substring(p,0, min(15,length(p))),'/','-'),'.','-')
} : null]

// Network Security Group (module) and ID (moved earlier)
module appgwNsg 'modules/appgateway-nsg.bicep' = if (createSubnetNsg) {
  name: 'appgwNsg'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    nsgName: naming.outputs.names.applicationGatewayNetworkSecurityGroup
    tags: tags
  }
}
var appgwNsgId = createSubnetNsg ? resourceId(subscription().subscriptionId, hubRgName, 'Microsoft.Network/networkSecurityGroups', naming.outputs.names.applicationGatewayNetworkSecurityGroup) : ''

// Route table (must exist before subnet for association)
module appgwRouteTable 'appgateway-route-table.bicep' = {
  name: 'appgwRouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: naming.outputs.names.applicationGatewayRouteTable
    firewallPrivateIp: firewallPrivateIp
    tags: tags
    internalForcedRouteEntries: effectiveInternalForcedRouteEntries
    // Disable default 0.0.0.0/0 route; only selective prefixes (from apps[].addressPrefix(es)) will be forced through Firewall
    includeDefaultRoute: false
  }
}

// Single authoritative subnet definition including NSG + route table association
module appgwSubnet 'appgateway-subnet.bicep' = {
  name: 'appgwSubnet'
  scope: resourceGroup(hubRgName)
  params: {
    hubVnetResourceId: hubVnetResourceId
    subnetName: appGatewaySubnetName
    addressPrefix: appGatewaySubnetAddressPrefix
    // Harden by default: disable implicit Internet egress; all outbound must follow explicit routes (Firewall)
    defaultOutboundAccess: false
    disablePrivateEndpointNetworkPolicies: disablePrivateEndpointNetworkPolicies
    routeTableId: appgwRouteTable.outputs.routeTableId
    nsgId: appgwNsgId
  }
  dependsOn: [
    appgwNsg
  ]
}

// Resolve or create WAF policy via dedicated module (eliminates conditional output warning)
module wafPolicyResolver 'modules/wafpolicy-resolver.bicep' = {
  name: 'wafPolicyResolver'
  scope: resourceGroup(hubRgName)
  params: {
    existingWafPolicyId: existingWafPolicyId
    location: location
    tags: tags
    mode: wafPolicyMode
    managedRuleSetVersion: wafManagedRuleSetVersion
    requestBodyCheck: wafRequestBodyCheck
    maxRequestBodySizeInKb: wafMaxRequestBodySizeInKb
    fileUploadLimitInMb: wafFileUploadLimitInMb
    policyName: naming.outputs.names.applicationGatewayWafPolicy
  }
}
var effectiveWafPolicyId = wafPolicyResolver.outputs.wafPolicyId

// Transform apps -> listeners (apps provide backendAddresses in correct shape)
// Listener shape: { name, hostNames?, backendAddresses: [{ipAddress|fqdn}], backendPort?, backendProtocol?, healthProbePath?, probeInterval?, probeTimeout?, unhealthyThreshold?, certificateSecretId }
var listeners = [for a in apps: {
  name: a.name
  hostNames: a.hostNames
  backendAddresses: a.backendAddresses
  backendPort: a.?backendPort
  backendProtocol: a.?backendProtocol
  healthProbePath: a.?healthProbePath
  // Per-listener probe tuning overrides (null falls back to defaults in core module)
  probeInterval: a.?probeInterval
  probeTimeout: a.?probeTimeout
  unhealthyThreshold: a.?unhealthyThreshold
  // Optional per-listener probe acceptable status codes override (array of ranges or codes)
  probeMatchStatusCodes: a.?probeMatchStatusCodes
  certificateSecretId: a.certificateSecretId
  // Pass-through WAF per-listener fields
  wafPolicyId: a.?wafPolicyId
  wafExclusions: a.?wafExclusions
  wafOverrides: a.?wafOverrides
  // Optional explicit host header override for backend/probe if app only responds to custom internal FQDN
  backendHostHeader: a.?backendHostHeader
}]

// Map commonDefaults object keys to individual core parameters (with safe fallbacks)
var cd = commonDefaults
var defaultBackendPort        = cd.?backendPort ?? 443
var defaultBackendProtocol    = cd.?backendProtocol ?? 'Https'
var defaultHealthProbePath    = cd.?healthProbePath ?? '/'
var defaultProbeInterval      = cd.?probeInterval ?? 30
var defaultProbeTimeout       = cd.?probeTimeout ?? 30
var defaultUnhealthyThreshold = cd.?unhealthyThreshold ?? 3
var defaultProbeMatchStatusCodes = cd.?probeMatchStatusCodes ?? [ '200-399' ]
var httpsListenerPort         = cd.?listenerFrontendPort ?? 443
var enableHttp2               = cd.?enableHttp2 ?? true
var autoscaleMinCapacity      = cd.?autoscaleMinCapacity ?? 1
var autoscaleMaxCapacity      = cd.?autoscaleMaxCapacity ?? 2
// Generated per-listener WAF policy defaults (if ever used) map from cd as well (optional)
// Baseline per-listener inheritance values mirror the global WAF policy (unless explicitly overridden via commonDefaults)
var generatedPolicyMode                    = cd.?generatedPolicyMode ?? wafPolicyMode
var generatedPolicyRequestBodyCheck        = cd.?generatedPolicyRequestBodyCheck ?? wafRequestBodyCheck
var generatedPolicyMaxRequestBodySizeInKb  = cd.?generatedPolicyMaxRequestBodySizeInKb ?? wafMaxRequestBodySizeInKb
var generatedPolicyFileUploadLimitInMb     = cd.?generatedPolicyFileUploadLimitInMb ?? wafFileUploadLimitInMb
var generatedPolicyManagedRuleSetVersion   = cd.?generatedPolicyManagedRuleSetVersion ?? wafManagedRuleSetVersion

// Multi-frontend removed (Gov limitation). Single public IP only.

// Core App Gateway (single module)
module appgwCore 'appgateway-core.bicep' = {
  name: 'appgwCore'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    appGatewayName: naming.outputs.names.applicationGateway
    publicIpName: naming.outputs.names.applicationGatewayPublicIPAddress
    subnetId: appgwSubnet.outputs.subnetId
    wafPolicyId: effectiveWafPolicyId
    // Defaults
    defaultBackendPort: defaultBackendPort
    defaultBackendProtocol: defaultBackendProtocol
    defaultHealthProbePath: defaultHealthProbePath
    defaultProbeInterval: defaultProbeInterval
    defaultProbeTimeout: defaultProbeTimeout
    defaultUnhealthyThreshold: defaultUnhealthyThreshold
  defaultProbeMatchStatusCodes: defaultProbeMatchStatusCodes
    generatedPolicyMode: generatedPolicyMode
    generatedPolicyRequestBodyCheck: generatedPolicyRequestBodyCheck
    generatedPolicyMaxRequestBodySizeInKb: generatedPolicyMaxRequestBodySizeInKb
    generatedPolicyFileUploadLimitInMb: generatedPolicyFileUploadLimitInMb
    generatedPolicyManagedRuleSetVersion: generatedPolicyManagedRuleSetVersion
    listeners: listeners
    httpsListenerPort: httpsListenerPort
    enableHttp2: enableHttp2
    autoscaleMinCapacity: autoscaleMinCapacity
    autoscaleMaxCapacity: autoscaleMaxCapacity
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    baseWafPolicyName: naming.outputs.names.applicationGatewayWafPolicy
  }
}

// Diagnostics (conditional)
var effectiveEnableDiagnostics = enableDiagnostics && !empty(logAnalyticsWorkspaceResourceId)
// Derive workspace name from resource ID (last segment) for conditional creation if it doesn't exist yet
var workspaceIdSegments = !empty(logAnalyticsWorkspaceResourceId) ? split(logAnalyticsWorkspaceResourceId, '/') : []
var workspaceName = !empty(logAnalyticsWorkspaceResourceId) ? workspaceIdSegments[length(workspaceIdSegments)-1] : ''
// Create Log Analytics workspace via module if diagnostics enabled.
module laWorkspace 'loganalytics-workspace.bicep' = if (effectiveEnableDiagnostics) {
  name: 'appgwLogAnalytics'
  scope: resourceGroup(hubRgName)
  params: {
    name: workspaceName
    location: location
    tags: tags
    retentionDays: 30
  }
}
module appgwDiagnostics 'appgateway-diagnostics.bicep' = {
  name: 'appgwDiagnostics'
  scope: resourceGroup(hubRgName)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    appGatewayName: naming.outputs.names.applicationGateway
    enable: effectiveEnableDiagnostics
  }
}

// (Removed second subnet association module; single subnet definition pattern)

// Firewall rules module (always deploy baseline + any custom groups)
module appGwFirewallRules 'modules/appgateway-firewall-rules.bicep' = {
  name: 'appGwFirewallRules'
  scope: resourceGroup(hubRgName)
  params: {
    firewallPolicyResourceId: firewallPolicyResourceId
    customRuleCollectionGroups: customAppGatewayFirewallRuleCollectionGroups
    // Supply backend prefixes derived from apps for explicit allow rule
    backendPrefixes: dedupPrefixes
    appGatewaySubnetPrefix: appGatewaySubnetAddressPrefix
    backendAllowPorts: backendAllowPorts
    backendPrefixPortMaps: backendPrefixPortMaps
    backendAppPortMaps: backendAppPortMaps
  }
}

output appGatewayResourceId string = appgwCore.outputs.appGatewayResourceId
output appGatewayPublicIp string = appgwCore.outputs.publicIpAddress
output wafPolicyResourceId string = effectiveWafPolicyId
output listenerNames array = appgwCore.outputs.listenerNames
output backendPoolNames array = appgwCore.outputs.backendPoolNames
output forcedRouteEntries array = effectiveInternalForcedRouteEntries
// Diagnostics output intentionally omitted to avoid conditional module reference at compile time
output diagnosticsSettingId string = effectiveEnableDiagnostics ? appgwDiagnostics.outputs.diagnosticsSettingId : ''
