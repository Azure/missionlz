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
@description('Common default settings object applied to each app unless overridden')
param commonDefaults object
@description('Array of application definitions (listeners, backend targets, optional overrides)')
param apps array
@description('Tags to apply to all created resources')
param tags object = {}
@description('Existing WAF policy resource ID (if provided, skip creating new policy)')
param existingWafPolicyId string = ''
@description('Whether to create and associate an NSG to the App Gateway subnet.')
param createSubnetNsg bool = true
@description('Optional custom firewall rule collection groups for App Gateway egress. If empty, an opinionated default group will be created.')
param customAppGatewayFirewallRuleCollectionGroups array = []
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
@description('Existing User Assigned Identity resource ID granting Key Vault secret get access for TLS certs')
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

// TODO (future): Add route table routes pointing 0.0.0.0/0 to Firewall private IP once module available.

// Ensure subnet
module appgwSubnet 'appgateway-subnet.bicep' = {
  name: 'appgwSubnet'
  scope: resourceGroup(hubRgName)
  params: {
    hubVnetResourceId: hubVnetResourceId
    subnetName: appGatewaySubnetName
    addressPrefix: appGatewaySubnetAddressPrefix
  }
}

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

// Route table (dedicated for App Gateway subnet) using naming convention
module appgwRouteTable 'appgateway-route-table.bicep' = {
  name: 'appgwRouteTable'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    routeTableName: naming.outputs.names.applicationGatewayRouteTable
    firewallPrivateIp: firewallPrivateIp
    tags: tags
  }
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
  }
}
var effectiveWafPolicyId = wafPolicyResolver.outputs.wafPolicyId

// Transform apps -> listeners (now expecting apps to already provide backendAddresses in correct shape)
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
  certificateSecretId: a.certificateSecretId
  wafPolicyId: null
  wafExclusions: null
}]

// Map commonDefaults object keys to individual core parameters (with safe fallbacks)
var cd = commonDefaults
var defaultBackendPort        = cd.?backendPort ?? 443
var defaultBackendProtocol    = cd.?backendProtocol ?? 'Https'
var defaultHealthProbePath    = cd.?healthProbePath ?? '/'
var defaultProbeInterval      = cd.?probeInterval ?? 30
var defaultProbeTimeout       = cd.?probeTimeout ?? 30
var defaultUnhealthyThreshold = cd.?unhealthyThreshold ?? 3
var httpsListenerPort         = cd.?listenerFrontendPort ?? 443
var enableHttp2               = cd.?enableHttp2 ?? true
var autoscaleMinCapacity      = cd.?autoscaleMinCapacity ?? 1
var autoscaleMaxCapacity      = cd.?autoscaleMaxCapacity ?? 2
// Generated per-listener WAF policy defaults (if ever used) map from cd as well (optional)
var generatedPolicyMode                    = cd.?generatedPolicyMode ?? 'Prevention'
var generatedPolicyRequestBodyCheck        = cd.?generatedPolicyRequestBodyCheck ?? true
var generatedPolicyMaxRequestBodySizeInKb  = cd.?generatedPolicyMaxRequestBodySizeInKb ?? 128
var generatedPolicyFileUploadLimitInMb     = cd.?generatedPolicyFileUploadLimitInMb ?? 100
var generatedPolicyManagedRuleSetVersion   = cd.?generatedPolicyManagedRuleSetVersion ?? '3.2'

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
  }
}

// Diagnostics (conditional)
var effectiveEnableDiagnostics = enableDiagnostics && !empty(logAnalyticsWorkspaceResourceId)
module appgwDiagnostics 'appgateway-diagnostics.bicep' = {
  name: 'appgwDiagnostics'
  scope: resourceGroup(hubRgName)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    appGatewayName: naming.outputs.names.applicationGateway
    enable: effectiveEnableDiagnostics
  }
}

// Network Security Group (module) and subnet association
module appgwNsg 'modules/appgateway-nsg.bicep' = if (createSubnetNsg) {
  name: 'appgwNsg'
  scope: resourceGroup(hubRgName)
  params: {
    location: location
    nsgName: naming.outputs.names.applicationGatewayNetworkSecurityGroup
    tags: tags
  }
}
// Derive NSG ID directly (avoids referencing conditional module output)
var appgwNsgId = createSubnetNsg ? resourceId(subscription().subscriptionId, hubRgName, 'Microsoft.Network/networkSecurityGroups', naming.outputs.names.applicationGatewayNetworkSecurityGroup) : ''
module subnetAssoc 'modules/appgateway-subnet-assoc.bicep' = {
  name: 'appgwSubnetAssoc'
  scope: resourceGroup(hubRgName)
  params: {
    hubVnetResourceId: hubVnetResourceId
    subnetName: appGatewaySubnetName
    addressPrefix: appGatewaySubnetAddressPrefix
    routeTableId: appgwRouteTable.outputs.routeTableId
    nsgId: appgwNsgId
  }
  dependsOn: [
    appgwSubnet
  ]
}

// (Removed unused existing hub VNet reference; subnet association handled in module)

// Firewall rules module (always deploy baseline + any custom groups)
module appGwFirewallRules 'modules/appgateway-firewall-rules.bicep' = {
  name: 'appGwFirewallRules'
  scope: resourceGroup(hubRgName)
  params: {
    firewallPolicyResourceId: firewallPolicyResourceId
    customRuleCollectionGroups: customAppGatewayFirewallRuleCollectionGroups
  }
}

output appGatewayResourceId string = appgwCore.outputs.appGatewayResourceId
output appGatewayPublicIp string = appgwCore.outputs.publicIpAddress
output wafPolicyResourceId string = effectiveWafPolicyId
output listenerNames array = appgwCore.outputs.listenerNames
output backendPoolNames array = appgwCore.outputs.backendPoolNames
// Diagnostics output intentionally omitted to avoid conditional module reference at compile time
output diagnosticsSettingId string = effectiveEnableDiagnostics ? appgwDiagnostics.outputs.diagnosticsSettingId : ''
