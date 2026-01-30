// solution.bicep - Orchestrates Scenario A Application Gateway WAF_v2 before Firewall
// NOTE: Initial scaffold; resources not fully implemented yet.
targetScope = 'subscription'

@description('Address prefix for the dedicated Application Gateway subnet (must be within hub VNet and unused). Platform recommendation for WAF_v2 is /24 for maximum future autoscale headroom; minimum supported is /26. Using /26 here by design to conserve address space.')
param appGatewaySubnetAddressPrefix string = '10.0.129.0/26'

@description('Subnet name for the Application Gateway.')
param appGatewaySubnetName string = 'AppGateway'

@description('Array of application definitions. Each app: { name, hostNames:[string...], backendAddresses:[{ipAddress|fqdn}], certificateSecretId, addressPrefixes:[CIDR... REQUIRED], (optional) backendPort, (optional) backendProtocol, (optional) healthProbePath, (optional) wafOverrides:{ mode, requestBodyCheck, maxRequestBodySizeInKb, fileUploadLimitInMb, managedRuleSetVersion }, (optional) wafExclusions, (optional) wafPolicyId }. NOTE: addressPrefixes is REQUIRED for routing and firewall rule generation.')
param apps array

@description('Destination ports to allow from Application Gateway subnet to backend prefixes (array of strings, supports ranges e.g. 443-445).')
param backendAllowPorts array = [ '443' ]

@description('Derived per-listener backend port maps (do not set manually).')
param backendAppPortMaps array = []

@description('Internal: future manual override for per-prefix port maps (leave empty).')
param backendPrefixPortMaps array = []

@description('Common default settings object applied to each app unless overridden')
param commonDefaults object

@description('Optional custom firewall rule collection groups for App Gateway egress. If empty, an opinionated default group will be created.')
param customAppGatewayFirewallRuleCollectionGroups array = []

@allowed([
  '-'
  ''
])
@description('Delimiter used in MLZ naming convention (pass through from core).')
param delimiter string = '-'

@description('A suffix to use for uniquely naming deployment-scoped modules (not part of resource names).')
param deploymentNameSuffix string = utcNow()

@allowed([
  'dev'
  'prod'
  'test'
])
@description('[dev/prod/test] The abbreviation for the target environment.')
param environmentAbbreviation string = 'dev'

@description('Existing WAF policy resource ID (if provided, skip creating new policy)')
param existingWafPolicyId string = ''

// Extract hub resource group name early for later parameter defaults
var hubRgName = split(hubVnetResourceId, '/')[4]

@description('Hub VNet resource ID where AppGateway subnet will reside')
param hubVnetResourceId string

@minLength(1)
@maxLength(5)
@description('1-5 alphanumeric characters without whitespace, used to name resources and generate uniqueness for resources within your subscription. Ideally, the value should represent an organization, department, or business unit.')
param identifier string

@description('Optional override for Key Vault resource group (defaults to hub RG).')
param keyVaultResourceGroupName string = ''

@description('Azure region for deployment')
param location string

@description('Network name token for naming (e.g. hub). If not provided inferred from hub VNet name segmentation.')
param networkName string = 'hub'

@description('Resource ID of the operations Log Analytics Workspace used for diagnostics (leave empty to skip).')
param operationsLogAnalyticsWorkspaceResourceId string = ''

@description('A single word value to describe the purpose the application gateway. This value is used in the resource names.')
param purpose string = ''

@description('Tags to apply to all created resources')
param tags object = {}

@description('Optional file upload limit (MB) when creating new WAF policy.')
param wafFileUploadLimitInMb int = 100

@description('OWASP Core Rule Set version (e.g. 3.2, 3.1).')
param wafManagedRuleSetVersion string = '3.2'

@description('Optional max request body size (KB) when creating new WAF policy.')
param wafMaxRequestBodySizeInKb int = 128

// WAF policy tuning (applies only when creating a new policy via resolver)
@description('Desired WAF policy mode when creating new policy (Prevention or Detection).')
@allowed([
  'Prevention'
  'Detection'
])
param wafPolicyMode string = 'Prevention'

@description('Enable or disable WAF requestBodyCheck when creating policy.')
param wafRequestBodyCheck bool = true

// Derive Key Vault name from first available certificate secret Id (default or first app) so we can assign RBAC role automatically
// Secret ID format: https://{vaultname}.vault.* /secrets/{secret}/{version}
var baseSecretId = (contains(commonDefaults, 'defaultCertificateSecretId') && !empty(commonDefaults.defaultCertificateSecretId)) ? commonDefaults.defaultCertificateSecretId : (!empty(apps) ? apps[0].certificateSecretId : '')
var effectiveKeyVaultRg = empty(keyVaultResourceGroupName) ? hubRgName : keyVaultResourceGroupName
// Extract vault name robustly: split on '//' then take host, then take first segment before '.vault'
var keyVaultHost = !empty(baseSecretId) ? split(split(baseSecretId, '//')[1], '/')[0] : ''
var keyVaultName = !empty(keyVaultHost) ? substring(keyVaultHost, 0, indexOf(keyVaultHost, '.vault')) : ''
var keyVaultRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
var locationAbbreviation = loadJsonContent('../../data/locations.json')[location].abbreviation
var resourceAbbreviations = loadJsonContent('../../data/resource-abbreviations.json')

// Identity is ALWAYS created (idempotent) using MLZ naming convention output (userAssignedIdentity)
// Placed after naming module so we can reference naming.outputs.names.userAssignedIdentity.

// Role assignment giving the user-assigned identity access to read secrets from the Key Vault (RBAC mode)
// Deterministic GUID naming: delete any pre-existing random assignment once, then future redeploys are clean
// NOTE: Compiler limitations prevent safe early access to conditional module outputs without warnings.
// For simplicity in this revision, automatic Key Vault role assignment is deferred when creating the identity in the same deployment.
// Users can perform RBAC assignment in a subsequent deployment or manually.
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

// User-assigned identity creation (RG-scoped)
module userAssignedIdentity 'modules/user-assigned-identity.bicep' = {
  name: 'userAssignedIdentity'
  scope: resourceGroup(hubRgName)
  params: {
    identityName: empty(purpose) ? replace(naming.outputs.names.userAssignedIdentity, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.userAssignedIdentity, naming.outputs.tokens.purpose, purpose)
    location: location
    tags: tags
  }
}
var effectiveUserAssignedIdentityResourceId = userAssignedIdentity.outputs.identityResourceId

// Key Vault Secrets read role assignment now ALWAYS applied when a certificate secret vault can be inferred
module kvSecretsReader 'modules/kv-role-assignment.bicep' = if (!empty(keyVaultName)) {
  name: 'kvSecretsReader'
  scope: resourceGroup(effectiveKeyVaultRg)
  params: {
    keyVaultName: keyVaultName
    roleDefinitionId: keyVaultRoleDefinitionId
    principalId: userAssignedIdentity.outputs.principalId
    userAssignedIdentityResourceId: effectiveUserAssignedIdentityResourceId
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


// Resolve firewall private IP via RG-scoped helper (avoids direct runtime property access in subscription scope)
module resolveFirewallIp 'modules/resolve-firewall-ip.bicep' = {
  name: 'resolveFirewallIp'
  scope: resourceGroup(hubRgName)
  params: {
    firewallName: empty(purpose) ? replace(naming.outputs.names.azureFirewall, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.azureFirewall, naming.outputs.tokens.purpose, purpose)
  }
}
var firewallPrivateIp = resolveFirewallIp.outputs.privateIpAddress
var firewallPolicyResourceId = resourceId(subscription().subscriptionId, hubRgName, 'Microsoft.Network/firewallPolicies', empty(purpose) ? replace(naming.outputs.names.azureFirewallPolicy, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.azureFirewallPolicy, naming.outputs.tokens.purpose, purpose))
// Route table prefix derivation (multi-prefix, no validation). Fallback to prefix-derived label due to Bicep nested for limitations.
// Gather & deduplicate backend CIDR prefixes (apps[].addressPrefixes REQUIRED)
var appsPrefixMatrix = [for a in apps: a.addressPrefixes]
var allAppPrefixes = flatten(appsPrefixMatrix)
var dedupPrefixes = [for (p,i) in allAppPrefixes: (!empty(p) && indexOf(allAppPrefixes,p) == i) ? p : '']
// Simplified: rely on explicit backendPrefixPortMaps parameter for per-app custom port mappings.
// If empty, module will fall back to broad rule using backendPrefixes + backendAllowPorts.
// Build forced route entries; original comprehension produced null placeholders. We use a ternary and then discard nulls via a second flattening step.
// Build forced route entries only for non-empty deduplicated prefixes (no null placeholders required now)
// Always create forced route entries for declared backend prefixes so traffic is steered through the Firewall.
// NOTE: Ensure corresponding return path considerations (backend subnets may also need UDRs) to avoid asymmetric flows.
var effectiveInternalForcedRouteEntries = [for p in dedupPrefixes: !empty(p) ? {
  prefix: p
  source: replace(replace(substring(p,0, min(15,length(p))),'/','-'),'.','-')
} : null]

// Network Security Group (always created for enforced baseline hardening)
module appgwNsg 'modules/appgateway-nsg.bicep' = {
  name: 'appgwNsg'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    nsgName: empty(purpose) ? replace(naming.outputs.names.applicationGatewayNetworkSecurityGroup, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGatewayNetworkSecurityGroup, naming.outputs.tokens.purpose, purpose)
    tags: tags
  }
}
var appgwNsgId = resourceId(subscription().subscriptionId, hubRgName, 'Microsoft.Network/networkSecurityGroups', empty(purpose) ? replace(naming.outputs.names.applicationGatewayNetworkSecurityGroup, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGatewayNetworkSecurityGroup, naming.outputs.tokens.purpose, purpose))
// Route table (must exist before subnet for association)
module appgwRouteTable 'modules/appgateway-route-table.bicep' = {
  name: 'appgwRouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: empty(purpose) ? replace(naming.outputs.names.applicationGatewayRouteTable, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGatewayRouteTable, naming.outputs.tokens.purpose, purpose)
    firewallPrivateIp: firewallPrivateIp
    tags: tags
    internalForcedRouteEntries: effectiveInternalForcedRouteEntries
    // Disable default 0.0.0.0/0 route; only selective prefixes (from apps[].addressPrefix(es)) will be forced through Firewall
    includeDefaultRoute: false
  }
}

// Single authoritative subnet definition including NSG + route table association
module appgwSubnet 'modules/appgateway-subnet.bicep' = {
  name: 'appgwSubnet'
  scope: resourceGroup(hubRgName)
  params: {
    hubVnetResourceId: hubVnetResourceId
    subnetName: appGatewaySubnetName
    addressPrefix: appGatewaySubnetAddressPrefix
    // Harden by default: disable implicit Internet egress; all outbound must follow explicit routes (Firewall)
    defaultOutboundAccess: false
  // Private Endpoint network policies intentionally left enabled (default) because subnet must remain dedicated to Application Gateway; no Private Endpoints should be placed here.
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
    policyName: empty(purpose) ? replace(naming.outputs.names.applicationGatewayWafPolicy, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGatewayWafPolicy, naming.outputs.tokens.purpose, purpose)
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
// WAF precedence per listener (evaluated inside core module):
// 1) Explicit wafPolicyId on the app entry
// 2) Generated per-listener policy if wafExclusions or wafOverrides provided
// 3) None -> listener inherits global gateway firewallPolicy

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

// Single public IP (Azure Gov limitation).

// Core App Gateway (single module)
module appgwCore 'modules/appgateway-core.bicep' = {
  name: 'appgwCore'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    appGatewayName: empty(purpose) ? replace(naming.outputs.names.applicationGateway, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGateway, naming.outputs.tokens.purpose, purpose)
    publicIpName: empty(purpose) ? replace(naming.outputs.names.applicationGatewayPublicIPAddress, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGatewayPublicIPAddress, naming.outputs.tokens.purpose, purpose)
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
    userAssignedIdentityResourceId: effectiveUserAssignedIdentityResourceId
    baseWafPolicyName: empty(purpose) ? replace(naming.outputs.names.applicationGatewayWafPolicy, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGatewayWafPolicy, naming.outputs.tokens.purpose, purpose)
  }
}

// Diagnostics: always declare module; internal enable flag driven by presence of workspace ID
var diagnosticsEnabled = !empty(operationsLogAnalyticsWorkspaceResourceId)
module appgwDiagnostics 'modules/appgateway-diagnostics.bicep' = {
  name: 'appgwDiagnostics'
  scope: resourceGroup(hubRgName)
  params: {
    logAnalyticsWorkspaceId: operationsLogAnalyticsWorkspaceResourceId
    appGatewayName: empty(purpose) ? replace(naming.outputs.names.applicationGateway, '${naming.outputs.delimiter}${naming.outputs.tokens.purpose}', '') : replace(naming.outputs.names.applicationGateway, naming.outputs.tokens.purpose, purpose)
    enable: diagnosticsEnabled
  }
}


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
// Per-listener effective WAF policy IDs (blank string means inherited global policy)
output perListenerWafPolicyIds array = appgwCore.outputs.effectivePerListenerWafPolicyIds
output forcedRouteEntries array = effectiveInternalForcedRouteEntries
// Diagnostics output intentionally omitted to avoid conditional module reference at compile time
output diagnosticsSettingId string = diagnosticsEnabled ? appgwDiagnostics.outputs.diagnosticsSettingId : ''
output operationsLogAnalyticsWorkspaceResourceIdOut string = operationsLogAnalyticsWorkspaceResourceId
output userAssignedIdentityResourceIdOut string = effectiveUserAssignedIdentityResourceId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.outputs.principalId
