/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param environmentAbbreviation string
param locationAbbreviation string
param networkName string
param networkShortName string
param resourceAbbreviations object
param resourcePrefix string
param stampIndex string = '' // Optional: Added to support AVD deployments
param subscriptionId string
param tokens object

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `environmentAbbreviation` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

  The stampIndex is only used for AVD deployments. Refer to the AVD Add-On readme file for more information.

*/

var namingConvention = '${toLower(resourcePrefix)}-${empty(stampIndex) ? '' : '${stampIndex}-'}${tokens.resource}-${networkName}-${environmentAbbreviation}-${locationAbbreviation}'
var namingConvention_Service = '${toLower(resourcePrefix)}-${empty(stampIndex) ? '' : '${stampIndex}-'}${tokens.resource}-${tokens.service}-${networkName}-${environmentAbbreviation}-${locationAbbreviation}'

/*

  CALCULATED NAME VALUES

  Here we reference the naming conventions described above,
  then use the "replace()" function to insert unique resource abbreviations and name values into the naming convention.

  `storageAccount` and `keyVault` names have a unique naming convention:
  In an effort to reduce the likelihood of naming collisions, the uniqueString function calculates a value based on the resourcePrefix, environmentAbbreviation, and subscription ID.

*/

var names = {
  actionGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.actionGroups)
  applicationGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.desktopApplicationGroups)
  automationAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.automationAccounts)
  availabilitySet: replace(namingConvention, tokens.resource, resourceAbbreviations.availabilitySets)
  azureFirewall: replace(namingConvention, tokens.resource, resourceAbbreviations.azureFirewalls)
  azureFirewallPolicy: replace(namingConvention, tokens.resource, resourceAbbreviations.firewallPolicies)
  azureFirewallClientPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIpAddresses), tokens.service, 'client-${resourceAbbreviations.azureFirewalls}')
  azureFirewallManagementPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIpAddresses), tokens.service, 'mgmt-${resourceAbbreviations.azureFirewalls}')
  bastionHost: replace(namingConvention, tokens.resource, resourceAbbreviations.bastionHosts)
  bastionHostPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIpAddresses), tokens.service, resourceAbbreviations.bastionHosts)
  computeGallery: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.computeGallieries), '-', '_') // Compute Galleries do not support hyphens
  dataCollectionRuleAssociation: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionRuleAssociations)
  dataCollectionRule: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionRules)
  diskAccess: replace(namingConvention, tokens.resource, resourceAbbreviations.diskAccesses)
  diskEncryptionSet: replace(namingConvention, tokens.resource, resourceAbbreviations.diskEncryptionSets)
  hostPool: replace(namingConvention, tokens.resource, resourceAbbreviations.hostPools)
  hostPoolDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.hostPools)
  hostPoolNetworkInterface: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.hostPools)
  hostPoolPrivateEndpoint: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.hostPools)
  keyVault: take('${replace(replace(replace(namingConvention, tokens.resource, resourceAbbreviations.keyVaults), '-', ''), networkName, networkShortName)}${uniqueString(resourcePrefix, environmentAbbreviation, subscriptionId)}', 24)
  keyVaultDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.keyVaults)
  keyVaultNetworkInterface: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.keyVaults)
  keyVaultPrivateEndpoint: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.keyVaults)
  logAnalyticsWorkspace: replace(namingConvention, tokens.resource, resourceAbbreviations.logAnalyticsWorkspaces)
  logAnalyticsWorkspaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.logAnalyticsWorkspaces)
  netAppAccountCapacityPool: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppCapacityPools)
  netAppAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppAccounts)
  networkSecurityGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.networkSecurityGroups)
  networkWatcher: replace(namingConvention, tokens.resource, resourceAbbreviations.networkWatchers)
  privateLinkScope: replace(namingConvention, tokens.resource, resourceAbbreviations.privateLinkScopes)
  privateLinkScopeNetworkInterface: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.privateLinkScopes)
  privateLinkScopePrivateEndpoint: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.privateLinkScopes)
  recoveryServicesVault: replace(namingConvention, tokens.resource, resourceAbbreviations.recoveryServicesVaults)
  recoveryServicesNetworkInterface: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.recoveryServicesVaults)
  recoveryServicesPrivateEndpoint: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.recoveryServicesVaults)
  resourceGroup: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.resourceGroups)
  routeTable: replace(namingConvention, tokens.resource, resourceAbbreviations.routeTables)
  storageAccount: toLower(take('${replace(replace(replace(namingConvention, tokens.resource, resourceAbbreviations.storageAccounts), networkName, networkShortName), '-', '')}${uniqueString(resourcePrefix, environmentAbbreviation, subscriptionId)}', 24))
  storageAccountNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${tokens.service}-${resourceAbbreviations.storageAccounts}')
  storageAccountPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${tokens.service}-${resourceAbbreviations.storageAccounts}')
  subnet: replace(namingConvention, tokens.resource, resourceAbbreviations.subnets)
  userAssignedIdentity: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.userAssignedIdentities)
  virtualMachine: replace(replace(replace(replace(namingConvention, tokens.resource, resourceAbbreviations.virtualMachines), environmentAbbreviation, first(environmentAbbreviation)), tokens.network, networkShortName), '-', '')
  virtualMachineDisk: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.disks), tokens.service, resourceAbbreviations.virtualMachines)
  virtualMachineNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.network, networkName)
  virtualNetwork: replace(namingConvention, tokens.resource, resourceAbbreviations.virtualNetworks)
  workspace: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.workspaces)
  workspaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${tokens.service}-${resourceAbbreviations.workspaces}')
  workspaceNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${tokens.service}-${resourceAbbreviations.workspaces}')
  workspacePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${tokens.service}-${resourceAbbreviations.workspaces}')
}

output names object = names
