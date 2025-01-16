/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param environmentAbbreviation string
param location string
param networkName string
param networkShortName string
param resourcePrefix string
param stampIndex string = '' // Optional: Added to support AVD deployments
param tokens object = {
  purpose:'purpose_token'
  resource: 'resource_token'
  service: 'service_token'
}

var locations = loadJsonContent('../data/locations.json')[environment().name]
var locationAbbreviation = locations[location].abbreviation
var resourceAbbreviations = loadJsonContent('../data/resourceAbbreviations.json')

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `environmentAbbreviation` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

  The stampIndex is only used for AVD deployments. Refer to the AVD Add-On readme file for more information.

*/

var namingConvention = '${toLower(resourcePrefix)}-${empty(stampIndex) ? '' : '${stampIndex}-'}${tokens.resource}-${networkName}-${locationAbbreviation}-${environmentAbbreviation}'
var namingConvention_Service = '${toLower(resourcePrefix)}-${empty(stampIndex) ? '' : '${stampIndex}-'}${tokens.resource}-${networkName}-${tokens.service}-${locationAbbreviation}-${environmentAbbreviation}'

/*

  CALCULATED NAME VALUES

  Here we reference the naming conventions described above,
  then use the "replace()" function to insert unique resource abbreviations and name values into the naming convention.

  `storageAccount` and `keyVault` names have a unique naming convention:
  In an effort to reduce the likelihood of naming collisions, the uniqueString function calculates a value based on the resourcePrefix, environmentAbbreviation, and subscription ID.

*/

var names = {
  actionGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.actionGroups)
  applicationGroup: replace(namingConvention, tokens.resource, '${resourceAbbreviations.applicationGroups}-desktop')
  applicationInsights: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.applicationInsights)
  appServicePlan: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.appServicePlans)
  automationAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.automationAccounts)
  automationAccountDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.automationAccounts)
  automationAccountNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.automationAccounts)
  automationAccountPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.automationAccounts)
  availabilitySet: replace(namingConvention, tokens.resource, resourceAbbreviations.availabilitySets)
  azureFirewall: replace(namingConvention, tokens.resource, resourceAbbreviations.azureFirewalls)
  azureFirewallClientPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, 'client-${resourceAbbreviations.azureFirewalls}')
  azureFirewallClientPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}-client-${resourceAbbreviations.azureFirewalls}')
  azureFirewallDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.azureFirewalls)
  azureFirewallManagementPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, 'mgmt-${resourceAbbreviations.azureFirewalls}')
  azureFirewallManagementPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}-mgmt-${resourceAbbreviations.azureFirewalls}')
  azureFirewallPolicy: replace(namingConvention, tokens.resource, resourceAbbreviations.firewallPolicies)
  bastionHost: replace(namingConvention, tokens.resource, resourceAbbreviations.bastionHosts)
  bastionHostNetworkSecurityGroup: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkSecurityGroups), tokens.service, resourceAbbreviations.bastionHosts)
  bastionHostDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.bastionHosts)
  bastionHostPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, resourceAbbreviations.bastionHosts)
  bastionHostPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}-${resourceAbbreviations.bastionHosts}')
  computeGallery: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.computeGallieries), '-', '_') // Compute Galleries do not support hyphens
  dataCollectionEndpoint: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionEndpoints)
  dataCollectionRuleAssociation: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionRuleAssociations)
  dataCollectionRule: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionRules)
  diskAccess: replace(namingConvention, tokens.resource, resourceAbbreviations.diskAccesses)
  diskAccessNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.diskAccesses)
  diskAccessPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.diskAccesses)
  diskEncryptionSet: replace(namingConvention, tokens.resource, resourceAbbreviations.diskEncryptionSets)
  functionApp: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.functionApps)
  functionAppNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.functionApps}-${tokens.service}')
  functionAppPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.functionApps}-${tokens.service}')
  hostPool: replace(namingConvention, tokens.resource, resourceAbbreviations.hostPools)
  hostPoolDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.hostPools)
  hostPoolNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.hostPools)
  hostPoolPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.hostPools)
  keyVault: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.keyVaults), '-', ''), networkName, networkShortName)
  keyVaultDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.keyVaults}-${tokens.service}')
  keyVaultNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.keyVaults}-${tokens.service}')
  keyVaultPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.keyVaults}-${tokens.service}')
  logAnalyticsWorkspace: replace(namingConvention, tokens.resource, resourceAbbreviations.logAnalyticsWorkspaces)
  logAnalyticsWorkspaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.logAnalyticsWorkspaces)
  natGateway: replace(namingConvention, tokens.resource, resourceAbbreviations.natGateway)
  natGatewayPublicIpPrefix: replace(namingConvention, tokens.resource, resourceAbbreviations.publicIpPrefixes)
  netAppAccountCapacityPool: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppCapacityPools)
  netAppAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppAccounts)
  networkSecurityGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.networkSecurityGroups)
  networkSecurityGroupDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.networkSecurityGroups)
  networkWatcher: replace(namingConvention, tokens.resource, resourceAbbreviations.networkWatchers)
  privateLinkScope: replace(namingConvention, tokens.resource, resourceAbbreviations.privateLinkScopes)
  privateLinkScopeNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.privateLinkScopes)
  privateLinkScopePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.privateLinkScopes)
  recoveryServicesVault: replace(namingConvention, tokens.resource, resourceAbbreviations.recoveryServicesVaults)
  recoveryServicesVaultNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.recoveryServicesVaults)
  recoveryServicesVaultPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.recoveryServicesVaults)
  resourceGroup: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.resourceGroups)
  routeTable: replace(namingConvention, tokens.resource, resourceAbbreviations.routeTables)
  scalingPlan: replace(namingConvention, tokens.resource, resourceAbbreviations.scalingPlans)
  scalingPlanDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.scalingPlans)
  storageAccount: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.storageAccounts), networkName, networkShortName)
  storageAccountDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${tokens.service}-${resourceAbbreviations.storageAccounts}')
  storageAccountBlobNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}-blob')
  storageAccountFileNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}-file')
  storageAccountQueueNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}-queue')
  storageAccountTableNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}-table')
  storageAccountBlobPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}-blob')
  storageAccountFilePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}-file')
  storageAccountQueuePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}-queue')
  storageAccountTablePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}-table')
  subnet: replace(namingConvention, tokens.resource, resourceAbbreviations.subnets)
  userAssignedIdentity: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.userAssignedIdentities)
  virtualMachine: replace(replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.virtualMachines), environmentAbbreviation, first(environmentAbbreviation)), networkName, ''), '-', '')
  virtualMachineDisk: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.disks), tokens.service, '${tokens.service}-${resourceAbbreviations.virtualMachines}')
  virtualMachineNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${tokens.service}-${resourceAbbreviations.virtualMachines}')
  virtualNetwork: replace(namingConvention, tokens.resource, resourceAbbreviations.virtualNetworks)
  virtualNetworkDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.virtualNetworks)
  workspaceFeed: replace(replace(namingConvention, tokens.resource, '${resourceAbbreviations.workspaces}-feed'), '-${stampIndex}', '')
  workspaceFeedDiagnosticSetting: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.workspaces}-feed'), '-${stampIndex}', '')
  workspaceFeedNetworkInterface: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.workspaces}-feed'), '-${stampIndex}', '')
  workspaceFeedPrivateEndpoint: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.workspaces}-feed'), '-${stampIndex}', '')
  workspaceGlobal: replace(replace(namingConvention, tokens.resource, '${resourceAbbreviations.workspaces}-global'), '-${stampIndex}', '')
  workspaceGlobalDiagnosticSetting: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.workspaces}-global'), '-${stampIndex}', '')
  workspaceGlobalNetworkInterface: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.workspaces}-global'), '-${stampIndex}', '')
  workspaceGlobalPrivateEndpoint: replace(replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.workspaces}-global'), '-${stampIndex}', '')
}

output locations object = locations
output names object = names
output resourceAbbreviations object = resourceAbbreviations
output tokens object = tokens
