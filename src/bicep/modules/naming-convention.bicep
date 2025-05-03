/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@allowed([
  '' // none
  '-' // hyphen
  '_' // underscore
])
param delimiter string = '-'
param environmentAbbreviation string
param location string
param networkName string
param identifier string

var locations = loadJsonContent('../data/locations.json')[environment().name]
var locationAbbreviation = locations[location].abbreviation
var resourceAbbreviations = loadJsonContent('../data/resource-abbreviations.json')
var tokens = {
  purpose: 'purpose_token'
  resource: 'resource_token'
  service: 'service_token'
}

/*

  NAMING CONVENTION VARIABLES

  The two variables below define the naming convention for all the resources deployed in MLZ and the MLZ add-ons. The concepts below
  adhere to the best practices in the Cloud Adoption Framework. Resource names are defined using a different naming 
  components that are separated by a delimiter. The components are:

  - identifier: A unique identifier for the resource. This is typically a short name or abbreviation that represents an organization, department, or business unit.
  - environmentAbbreviation: A short abbreviation that represents the environment in which the resource is deployed. Common values include "prod" for production, "dev" for development, and "test" for testing.
  - locationAbbreviation: A short abbreviation that represents the geographical location of the resource. This is a two to four letter code that corresponds to the Azure region in which the resource is deployed.
  - networkName: A name that represents the network tier in which the resource is deployed.
  - tokens.resource: This is a placeholder value for the resource type that is replaced in the "names" var.
  - tokens.service: This is a placeholder value for the service type, typically representing a parent child relationship, that is replaced in the "names" var.
  - tokens.purpose: This is a placeholder value for the purpose of the resource that is replaced in the resource deployments.

*/

var namingConvention = '${toLower(identifier)}${delimiter}${environmentAbbreviation}${delimiter}${locationAbbreviation}${delimiter}${networkName}${delimiter}${tokens.resource}${delimiter}${tokens.purpose}'
var namingConvention_Service = '${toLower(identifier)}${delimiter}${environmentAbbreviation}${delimiter}${locationAbbreviation}${delimiter}${networkName}${delimiter}${tokens.resource}${delimiter}${tokens.service}${delimiter}${tokens.purpose}'

/*

  NAMES VARIABLE

  In the variable below, the names are generated using the "replace()" function to insert unique values into the token components.

  Warning!
  In an effort to reduce the likelihood of naming collisions, the name defined for global resources will be passed into a "uniqueString()" function for the deployment.

*/

var names = {
  actionGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.actionGroups)
  applicationGroup: replace(namingConvention, tokens.resource, '${resourceAbbreviations.applicationGroups}${delimiter}${resourceAbbreviations.applicationGroupsDesktop}')
  applicationInsights: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.applicationInsights)
  appServicePlan: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.appServicePlans)
  automationAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.automationAccounts)
  automationAccountDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.automationAccounts)
  automationAccountNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.automationAccounts)
  automationAccountPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.automationAccounts)
  availabilitySet: replace(namingConvention, tokens.resource, resourceAbbreviations.availabilitySets)
  azureFirewall: replace(namingConvention, tokens.resource, resourceAbbreviations.azureFirewalls)
  azureFirewallClientPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, '${resourceAbbreviations.azureFirewalls}${delimiter}${resourceAbbreviations.azureFirewallsClient}')
  azureFirewallClientPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}${delimiter}${resourceAbbreviations.azureFirewalls}${delimiter}${resourceAbbreviations.azureFirewallsClient}')
  azureFirewallDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.azureFirewalls)
  azureFirewallManagementPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, '${resourceAbbreviations.azureFirewalls}${delimiter}${resourceAbbreviations.azureFirewallsManagement}')
  azureFirewallManagementPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}${delimiter}${resourceAbbreviations.azureFirewalls}${delimiter}${resourceAbbreviations.azureFirewallsManagement}')
  azureFirewallPolicy: replace(namingConvention, tokens.resource, resourceAbbreviations.firewallPolicies)
  bastionHost: replace(namingConvention, tokens.resource, resourceAbbreviations.bastionHosts)
  bastionHostDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.bastionHosts)
  bastionHostNetworkSecurityGroup: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkSecurityGroups), tokens.service, resourceAbbreviations.bastionHosts)
  bastionHostNetworkSecurityGroupDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.networkSecurityGroups}${delimiter}${resourceAbbreviations.bastionHosts}')
  bastionHostPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, resourceAbbreviations.bastionHosts)
  bastionHostPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}${delimiter}${resourceAbbreviations.bastionHosts}')
  computeGallery: replace(replace(namingConvention, tokens.resource, resourceAbbreviations.computeGallieries), delimiter, empty(delimiter) ? '' : '_') // Compute Galleries do not support hyphens
  dataCollectionEndpoint: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionEndpoints)
  dataCollectionRuleAssociation: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionRuleAssociations)
  dataCollectionRule: replace(namingConvention, tokens.resource, resourceAbbreviations.dataCollectionRules)
  diskAccess: replace(namingConvention, tokens.resource, resourceAbbreviations.diskAccesses)
  diskAccessNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.diskAccesses)
  diskAccessPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.diskAccesses)
  diskEncryptionSet: replace(namingConvention, tokens.resource, resourceAbbreviations.diskEncryptionSets)
  functionApp: replace(namingConvention_Service, tokens.resource, resourceAbbreviations.functionApps)
  functionAppNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.functionApps}${delimiter}${tokens.service}')
  functionAppPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.functionApps}${delimiter}${tokens.service}')
  hostPool: replace(namingConvention, tokens.resource, resourceAbbreviations.hostPools)
  hostPoolDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.hostPools)
  hostPoolNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.hostPools)
  hostPoolPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.hostPools)
  keyVault: replace(namingConvention, tokens.resource, resourceAbbreviations.keyVaults)
  keyVaultDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.keyVaults}')
  keyVaultNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.keyVaults}${delimiter}${tokens.service}')
  keyVaultPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.keyVaults}${delimiter}${tokens.service}')
  logAnalyticsWorkspace: replace(namingConvention, tokens.resource, resourceAbbreviations.logAnalyticsWorkspaces)
  logAnalyticsWorkspaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.logAnalyticsWorkspaces)
  netAppAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppAccounts)
  netAppAccountCapacityPool: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppCapacityPools)
  netAppAccountSmbServer: replace(replace(replace(replace(namingConvention, tokens.resource, ''), environmentAbbreviation, first(environmentAbbreviation)), networkName, ''), delimiter, '')
  networkSecurityGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.networkSecurityGroups)
  networkSecurityGroupDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.networkSecurityGroups)
  networkWatcher: replace(namingConvention, tokens.resource, resourceAbbreviations.networkWatchers)
  networkWatcherFlowLogsNetworkSecurityGroup: replace(namingConvention, tokens.resource, '${resourceAbbreviations.networkWatchers}${delimiter}${resourceAbbreviations.networkWatchersFlowLogs}${delimiter}${resourceAbbreviations.networkSecurityGroups}')
  networkWatcherFlowLogsVirtualNetwork: replace(namingConvention, tokens.resource, '${resourceAbbreviations.networkWatchers}${delimiter}${resourceAbbreviations.networkWatchersFlowLogs}${delimiter}${resourceAbbreviations.virtualNetworks}')
  privateLinkScope: replace(namingConvention, tokens.resource, resourceAbbreviations.privateLinkScopes)
  privateLinkScopeNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.privateLinkScopes)
  privateLinkScopePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.privateLinkScopes)
  recoveryServicesVault: replace(namingConvention, tokens.resource, resourceAbbreviations.recoveryServicesVaults)
  recoveryServicesVaultNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.recoveryServicesVaults)
  recoveryServicesVaultPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.recoveryServicesVaults)
  resourceGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.resourceGroups)
  routeTable: replace(namingConvention, tokens.resource, resourceAbbreviations.routeTables)
  scalingPlan: replace(namingConvention, tokens.resource, resourceAbbreviations.scalingPlans)
  scalingPlanDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.scalingPlans)
  storageAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.storageAccounts)
  storageAccountDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${tokens.service}${delimiter}${resourceAbbreviations.storageAccounts}')
  storageAccountBlobNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsBlobServices}')
  storageAccountFileNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsFileServices}')
  storageAccountQueueNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsQueueServices}')
  storageAccountTableNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsTableServices}')
  storageAccountBlobPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsBlobServices}')
  storageAccountFilePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsFileServices}')
  storageAccountQueuePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsQueueServices}')
  storageAccountTablePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}${resourceAbbreviations.storageAccountsTableServices}')
  subnet: replace(namingConvention, tokens.resource, resourceAbbreviations.subnets)
  userAssignedIdentity: replace(namingConvention, tokens.resource, resourceAbbreviations.userAssignedIdentities)
  virtualMachine: replace(replace(replace(replace(namingConvention, tokens.resource, resourceAbbreviations.virtualMachines), environmentAbbreviation, first(environmentAbbreviation)), networkName, ''), delimiter, '')
  virtualMachineDisk: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.disks), tokens.service, '${resourceAbbreviations.virtualMachines}')
  virtualMachineNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${tokens.service}${delimiter}${resourceAbbreviations.virtualMachines}')
  virtualMachineNetworkInterfaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${tokens.service}${delimiter}${resourceAbbreviations.networkInterfaces}${delimiter}${resourceAbbreviations.virtualMachines}')
  virtualNetwork: replace(namingConvention, tokens.resource, resourceAbbreviations.virtualNetworks)
  virtualNetworkDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.virtualNetworks)
  workspaceFeed: replace(replace(namingConvention, tokens.resource, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesFeed}'), '${delimiter}${tokens.purpose}', '')
  workspaceFeedDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesFeed}')
  workspaceFeedNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesFeed}')
  workspaceFeedPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesFeed}')
  workspaceGlobal: replace(replace(namingConvention, tokens.resource, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesGlobal}'), '${delimiter}${tokens.purpose}', '')
  workspaceGlobalDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesGlobal}')
  workspaceGlobalNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesGlobal}')
  workspaceGlobalPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.workspaces}${delimiter}${resourceAbbreviations.workspacesGlobal}')
}

output locations object = locations
output names object = names
output resourceAbbreviations object = resourceAbbreviations
output tokens object = tokens
