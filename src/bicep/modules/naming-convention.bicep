/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

@allowed([
  '' // none
  '-' // hyphen
])
param delimiter string = '-'
param environmentAbbreviation string
param location string
param networkName string
param identifier string
param stampIndex string = '' // Enables multiple deployments of the same workload within a namespace

var directionShortNames = {
  east: 'e'
  eastcentral: 'ec'
  north: 'n'
  northcentral: 'nc'
  south: 's'
  southcentral: 'sc'
  west: 'w'
  westcentral: 'wc'
}
var locations = loadJsonContent('../data/locations.json')[?environment().name] ?? {
  '${location}': {
    abbreviation: directionShortNames[skip(location, length(location) - 4)]
    timeDifference: contains(location, 'east') ? '-5:00' : contains(location, 'west') ? '-8:00' : '0:00'
    timeZone: contains(location, 'east') ? 'Eastern Standard Time' : contains(location, 'west') ? 'Pacific Standard Time' : 'GMT Standard Time'
  }
}
var locationAbbreviation = locations[location].abbreviation
var resourceAbbreviations = loadJsonContent('../data/resource-abbreviations.json')
var tokens = {
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
  - stampIdex: A unique integer value that is used to identify the specific instance of a workload.

*/

var namingConvention = '${toLower(identifier)}${delimiter}${environmentAbbreviation}${delimiter}${locationAbbreviation}${delimiter}${networkName}${delimiter}${tokens.resource}${empty(stampIndex) ? '' : '${delimiter}${stampIndex}'}'
var namingConvention_Service = '${toLower(identifier)}${delimiter}${environmentAbbreviation}${delimiter}${locationAbbreviation}${delimiter}${networkName}${delimiter}${tokens.service}${delimiter}${tokens.resource}${empty(stampIndex) ? '' : '${delimiter}${stampIndex}'}'

/*

  NAMES VARIABLE

  In the variable below, the names are generated using the "replace()" function to insert unique values into the token components.

  Warning!
  In an effort to reduce the likelihood of naming collisions, the name defined for global resources will be passed into a "uniqueString()" function for the deployment.

*/

var names = {
  actionGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.actionGroups)
  applicationGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.applicationGroups)
  applicationInsights: replace(namingConvention, tokens.resource, resourceAbbreviations.applicationInsights)
  appServicePlan: replace(namingConvention, tokens.resource, resourceAbbreviations.appServicePlans)
  automationAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.automationAccounts)
  automationAccountDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.automationAccounts)
  automationAccountNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.automationAccounts)
  automationAccountPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.automationAccounts)
  availabilitySet: replace(namingConvention, tokens.resource, resourceAbbreviations.availabilitySets)
  azureFirewall: replace(namingConvention, tokens.resource, resourceAbbreviations.azureFirewalls)
  azureFirewallPublicIPAddress: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPAddresses), tokens.service, resourceAbbreviations.azureFirewalls)
  azureFirewallPublicIPAddressDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.publicIPAddresses}${delimiter}${resourceAbbreviations.azureFirewalls}')
  azureFirewallDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.azureFirewalls)
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
  functionApp: replace(namingConvention, tokens.resource, resourceAbbreviations.functionApps)
  functionAppNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.functionApps)
  functionAppPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.functionApps)
  hostPool: replace(namingConvention, tokens.resource, resourceAbbreviations.hostPools)
  hostPoolDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.hostPools)
  hostPoolNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.hostPools)
  hostPoolPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.hostPools)
  keyVault: replace(namingConvention, tokens.resource, resourceAbbreviations.keyVaults)
  keyVaultDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.keyVaults)
  keyVaultNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.keyVaults)
  keyVaultPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.keyVaults)
  localNetworkGateway: replace(namingConvention, tokens.resource, resourceAbbreviations.localNetworkGateways)
  logAnalyticsWorkspace: replace(namingConvention, tokens.resource, resourceAbbreviations.logAnalyticsWorkspaces)
  logAnalyticsWorkspaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.logAnalyticsWorkspaces)
  natGateway: replace(namingConvention, tokens.resource, resourceAbbreviations.natGateways)
  natGatewayPublicIPPrefix: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.publicIPPrefixes), tokens.service, resourceAbbreviations.natGateways)
  netAppAccount: replace(namingConvention, tokens.resource, resourceAbbreviations.netAppAccounts)
  netAppAccountCapacityPool: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.netAppAccountsCapacityPools), tokens.service, resourceAbbreviations.netAppAccounts)
  netAppAccountSmbServer: replace(replace(replace(replace(namingConvention, tokens.resource, ''), environmentAbbreviation, first(environmentAbbreviation)), networkName, ''), delimiter, '')
  networkSecurityGroup: replace(namingConvention, tokens.resource, resourceAbbreviations.networkSecurityGroups)
  networkSecurityGroupDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.networkSecurityGroups)
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
  storageAccountBlobDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}blob')
  storageAccountBlobNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}blob')
  storageAccountBlobPrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}blob')
  storageAccountFileDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}file')
  storageAccountFileNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}file')
  storageAccountFilePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}file')
  storageAccountQueueDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}queue')
  storageAccountQueueNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}queue')
  storageAccountQueuePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}queue')
  storageAccountTableDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}table')
  storageAccountTableNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}table')
  storageAccountTablePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, '${resourceAbbreviations.storageAccounts}${delimiter}table')
  subnet: replace(namingConvention, tokens.resource, resourceAbbreviations.subnets)
  userAssignedIdentity: replace(namingConvention, tokens.resource, resourceAbbreviations.userAssignedIdentities)
  virtualMachine: replace(replace(replace(replace(namingConvention, tokens.resource, resourceAbbreviations.virtualMachines), environmentAbbreviation, first(environmentAbbreviation)), networkName, ''), delimiter, '')
  virtualMachineDisk: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.disks), tokens.service, '${resourceAbbreviations.virtualMachines}')
  virtualMachineNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.virtualMachines)
  virtualMachineNetworkInterfaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, '${resourceAbbreviations.networkInterfaces}${delimiter}${resourceAbbreviations.virtualMachines}')
  virtualNetwork: replace(namingConvention, tokens.resource, resourceAbbreviations.virtualNetworks)
  virtualNetworkDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.virtualNetworks)
  virtualNetworkGateway: replace(namingConvention, tokens.resource, resourceAbbreviations.virtualNetworkGateways)
  workspace: replace(namingConvention, tokens.resource, resourceAbbreviations.workspaces)
  workspaceDiagnosticSetting: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.diagnosticSettings), tokens.service, resourceAbbreviations.workspaces)
  workspaceNetworkInterface: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.networkInterfaces), tokens.service, resourceAbbreviations.workspaces)
  workspacePrivateEndpoint: replace(replace(namingConvention_Service, tokens.resource, resourceAbbreviations.privateEndpoints), tokens.service, resourceAbbreviations.workspaces)
}

output delimiter string = delimiter
output locations object = locations
output names object = names
output resourceAbbreviations object = resourceAbbreviations
