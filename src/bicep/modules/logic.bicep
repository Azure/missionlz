targetScope = 'subscription'

param deployIdentity bool
param environmentAbbreviation string
param hubSubscriptionId string
param identityNetworkSecurityGroupDiagnosticsLogs array
param identityNetworkSecurityGroupDiagnosticsMetrics array
param identityNetworkSecurityGroupRules array
param identitySubnetAddressPrefix string
param identitySubscriptionId string
param identityVirtualNetworkAddressPrefix string
param identityVirtualNetworkDiagnosticsLogs array
param identityVirtualNetworkDiagnosticsMetrics array
param operationsNetworkSecurityGroupDiagnosticsLogs array
param operationsNetworkSecurityGroupDiagnosticsMetrics array
param operationsNetworkSecurityGroupRules array
param operationsSubnetAddressPrefix string
param operationsSubscriptionId string
param operationsVirtualNetworkAddressPrefix string
param operationsVirtualNetworkDiagnosticsLogs array
param operationsVirtualNetworkDiagnosticsMetrics array
param resourcePrefix string
param resources object
param sharedServicesNetworkSecurityGroupDiagnosticsLogs array
param sharedServicesNetworkSecurityGroupDiagnosticsMetrics array
param sharedServicesNetworkSecurityGroupRules array
param sharedServicesSubnetAddressPrefix string
param sharedServicesSubscriptionId string
param sharedServicesVirtualNetworkAddressPrefix string
param sharedServicesVirtualNetworkDiagnosticsLogs array
param sharedServicesVirtualNetworkDiagnosticsMetrics array
param tokens object

// NETWORK NAMES & SHORT NAMES

var hubName = 'hub'
var hubShortName = 'hub'
var identityName = 'identity'
var identityShortName = 'id'
var operationsName = 'operations'
var operationsShortName = 'ops'
var sharedServicesName = 'sharedServices'
var sharedServicesShortName = 'svcs'

var hub = {
  name: hubName
  subscriptionId: hubSubscriptionId
  resourceGroupName: replace(replace(resources.resourceGroup, '-${tokens.service}', ''), tokens.network, hubName)
  deployUniqueResources: true
  bastionHostIPConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'bas'), tokens.network, hubName)
  bastionHostName: replace(replace(resources.bastionHost, '-${tokens.service}', ''), tokens.network, hubName)
  bastionHostPublicIPAddressName: replace(replace(resources.publicIpAddress, tokens.service, 'bas'), tokens.network, hubName)
  diskEncryptionSetName: replace(replace(resources.diskEncryptionSet, '-${tokens.service}', ''), tokens.network, hubName)
  firewallClientIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'client-afw'), tokens.network, hubName)
  firewallClientPublicIPAddressName: replace(replace(resources.publicIpAddress, tokens.service, 'client-afw'), tokens.network, hubName)
  firewallManagementIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'mgmt-afw'), tokens.network, hubName)
  firewallManagementPublicIPAddressName: replace(replace(resources.publicIpAddress, tokens.service, 'mgmt-afw'), tokens.network, hubName)
  firewallName: replace(replace(resources.firewall, '-${tokens.service}', ''), tokens.network, hubName)
  firewallPolicyName: replace(replace(resources.firewallPolicy, '-${tokens.service}', ''), tokens.network, hubName)
  keyVaultName: take(replace(replace(replace(resources.keyVault, tokens.service, ''), tokens.network, hubShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, hubSubscriptionId)), 24)
  keyVaultNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'kv'), tokens.network, hubName)
  keyVaultPrivateEndpointName: replace(replace(resources.privateEndpoint, tokens.service, 'kv'), tokens.network, hubName)
  linuxDiskName: replace(replace(resources.disk, tokens.service, 'linux'), tokens.network, hubName)
  linuxNetworkInterfaceIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'linux'), tokens.network, hubName)
  linuxNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'linux'), tokens.network, hubName)
  linuxVmName: replace(replace(resources.virtualMachine, tokens.service, 'lra'), tokens.network, hubName)
  logStorageAccountName: take(replace(replace(replace(resources.storageAccount, tokens.service, ''), tokens.network, hubShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, hubSubscriptionId)), 24)
  logStorageAccountNetworkInterfaceNamePrefix: replace(replace(resources.networkInterface, tokens.service, '${tokens.service}-st'), tokens.network, hubName)
  logStorageAccountPrivateEndpointNamePrefix: replace(replace(resources.privateEndpoint, tokens.service, '${tokens.service}-st'), tokens.network, hubName)
  networkSecurityGroupName: replace(replace(resources.networkSecurityGroup, '-${tokens.service}', ''), tokens.network, hubName)
  networkWatcherName: replace(replace(resources.networkWatcher, '-${tokens.service}', ''), tokens.network, hubName)
  routeTableName: replace(replace(resources.routeTable, '-${tokens.service}', ''), tokens.network, hubName)
  subnetName: replace(replace(resources.subnet, '-${tokens.service}', ''), tokens.network, hubName)
  userAssignedIdentityName: replace(replace(resources.userAssignedIdentity, '-${tokens.service}', ''), tokens.network, hubName)
  virtualNetworkName: replace(replace(resources.virtualNetwork, '-${tokens.service}', ''), tokens.network, hubName)
  windowsDiskName: replace(replace(resources.disk, tokens.service, 'windows'), tokens.network, hubName)
  windowsNetworkInterfaceIpConfigurationName: replace(replace(resources.ipConfiguration, tokens.service, 'windows'), tokens.network, hubName)
  windowsNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'windows'), tokens.network, hubName)
  windowsVmName: replace(replace(resources.virtualMachine, tokens.service, 'wra'), tokens.network, hubName)
}

// SPOKES

var spokes = union(spokesCommon, spokesIdentity)
var spokesCommon = [
  {
    name: operationsName
    subscriptionId: operationsSubscriptionId
    resourceGroupName: replace(replace(resources.resourceGroup, '-${tokens.service}', ''), tokens.network, operationsName)
    deployUniqueResources: contains([ hubSubscriptionId ], operationsSubscriptionId) ? false : true
    logAnalyticsWorkspaceName: replace(replace(resources.logAnalyticsWorkspace, '-${tokens.service}', ''), tokens.network, operationsName)
    logStorageAccountName: take(replace(replace(replace(resources.storageAccount, tokens.service, ''), tokens.network, operationsShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, operationsSubscriptionId)), 24)
    logStorageAccountNetworkInterfaceNamePrefix: replace(replace(resources.networkInterface, tokens.service, '${tokens.service}-st'), tokens.network, operationsName)
    logStorageAccountPrivateEndpointNamePrefix: replace(replace(resources.privateEndpoint, tokens.service, '${tokens.service}-st'), tokens.network, operationsName)
    networkSecurityGroupDiagnosticsLogs: operationsNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: operationsNetworkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupName: replace(replace(resources.networkSecurityGroup, '-${tokens.service}', ''), tokens.network, operationsName)
    networkSecurityGroupRules: operationsNetworkSecurityGroupRules
    networkWatcherName: replace(replace(resources.networkWatcher, '-${tokens.service}', ''), tokens.network, operationsName)
    privateLinkScopeName: replace(replace(resources.privateLinkScope, '-${tokens.service}', ''), tokens.network, operationsName)
    privateLinkScopeNetworkInterfaceName: replace(replace(resources.networkInterface, tokens.service, 'pls'), tokens.network, operationsName)
    privateLinkScopePrivateEndpointName: replace(replace(resources.privateEndpoint, tokens.service, 'pls'), tokens.network, operationsName)
    routeTableName: replace(replace(resources.routeTable, '-${tokens.service}', ''), tokens.network, operationsName)
    subnetAddressPrefix: operationsSubnetAddressPrefix
    subnetName: replace(replace(resources.subnet, '-${tokens.service}', ''), tokens.network, operationsName)
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
    virtualNetworkAddressPrefix: operationsVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: operationsVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: operationsVirtualNetworkDiagnosticsMetrics
    virtualNetworkName: replace(replace(resources.virtualNetwork, '-${tokens.service}', ''), tokens.network, operationsName)
  }
  {
    name: sharedServicesName
    subscriptionId: sharedServicesSubscriptionId
    resourceGroupName: replace(replace(resources.resourceGroup, '-${tokens.service}', ''), tokens.network, sharedServicesName)
    deployUniqueResources: contains([ hubSubscriptionId, operationsSubscriptionId ], sharedServicesSubscriptionId) ? false : true
    logStorageAccountName: take(replace(replace(replace(resources.storageAccount, tokens.service, ''), tokens.network, sharedServicesShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, sharedServicesSubscriptionId)), 24)
    logStorageAccountNetworkInterfaceNamePrefix: replace(replace(resources.networkInterface, tokens.service, '${tokens.service}-st'), tokens.network, sharedServicesName)
    logStorageAccountPrivateEndpointNamePrefix: replace(replace(resources.privateEndpoint, tokens.service, '${tokens.service}-st'), tokens.network, sharedServicesName)
    networkSecurityGroupDiagnosticsLogs: sharedServicesNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: sharedServicesNetworkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupName: replace(replace(resources.networkSecurityGroup, '-${tokens.service}', ''), tokens.network, sharedServicesName)
    networkSecurityGroupRules: sharedServicesNetworkSecurityGroupRules
    networkWatcherName: replace(replace(resources.networkWatcher, '-${tokens.service}', ''), tokens.network, sharedServicesName)
    routeTableName: replace(replace(resources.routeTable, '-${tokens.service}', ''), tokens.network, sharedServicesName)
    subnetAddressPrefix: sharedServicesSubnetAddressPrefix
    subnetName: replace(replace(resources.subnet, '-${tokens.service}', ''), tokens.network, sharedServicesName)
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
    virtualNetworkAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics
    virtualNetworkName: replace(replace(resources.virtualNetwork, '-${tokens.service}', ''), tokens.network, sharedServicesName)
  }
]
var spokesIdentity = deployIdentity ? [
  {
    name: identityName
    subscriptionId: identitySubscriptionId
    resourceGroupName: replace(replace(resources.resourceGroup, '-${tokens.service}', ''), tokens.network, identityName)
    deployUniqueResources: contains([ hubSubscriptionId, operationsSubscriptionId, sharedServicesSubscriptionId ], identitySubscriptionId) ? false : true
    logStorageAccountName: take(replace(replace(replace(resources.storageAccount, tokens.service, ''), tokens.network, identityShortName), 'unique_token', uniqueString(resourcePrefix, environmentAbbreviation, identitySubscriptionId)), 24)
    logStorageAccountNetworkInterfaceNamePrefix: replace(replace(resources.networkInterface, tokens.service, '${tokens.service}-st'), tokens.network, identityName)
    logStorageAccountPrivateEndpointNamePrefix: replace(replace(resources.privateEndpoint, tokens.service, '${tokens.service}-st'), tokens.network, identityName)
    networkSecurityGroupDiagnosticsLogs: identityNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: identityNetworkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupName: replace(replace(resources.networkSecurityGroup, '-${tokens.service}', ''), tokens.network, identityName)
    networkSecurityGroupRules: identityNetworkSecurityGroupRules
    networkWatcherName: replace(replace(resources.networkWatcher, '-${tokens.service}', ''), tokens.network, identityName)
    routeTableName: replace(replace(resources.routeTable, '-${tokens.service}', ''), tokens.network, identityName)
    subnetAddressPrefix: identitySubnetAddressPrefix
    subnetName: replace(replace(resources.subnet, '-${tokens.service}', ''), tokens.network, identityName)
    subnetPrivateEndpointNetworkPolicies: 'Disabled'
    subnetPrivateLinkServiceNetworkPolicies: 'Disabled'
    virtualNetworkAddressPrefix: identityVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: identityVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: identityVirtualNetworkDiagnosticsMetrics
    virtualNetworkName: replace(replace(resources.virtualNetwork, '-${tokens.service}', ''), tokens.network, identityName)
  }
] : []

output networks array = union([
  hub
], spokes)
