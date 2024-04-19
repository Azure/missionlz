/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'

param environmentAbbreviation string
param location string
param resourcePrefix string

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `environmentAbbreviation` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

*/

var locations = (loadJsonContent('../data/locations.json'))[environment().name]
var locationAbbreviation = locations[location].abbreviation
var resourceAbbreviations = (loadJsonContent('../data/resourceAbbreviations.json'))
var resourceToken = 'resource_token'
var serviceToken = 'service_token'
var networkToken = 'network_token'
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${serviceToken}-${networkToken}-${environmentAbbreviation}-${locationAbbreviation}'

/*

  CALCULATED VALUES

  Here we reference the naming conventions described above,
  then use the "replace()" function to insert unique resource abbreviations and name values into the naming convention.

  `storageAccountNamingConvention` is a unique naming convention:
    
    In an effort to reduce the likelihood of naming collisions, 
    we replace `unique_token` with a uniqueString() calculated by resourcePrefix, environmentAbbreviation, and the subscription ID

*/

// RESOURCE NAME CONVENTIONS WITH ABBREVIATIONS

var actionGroupNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.actionGroups)
var automationAccountNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.automationAccounts)
var bastionHostNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.bastionHosts)
var computeGalleryNamingConvention = replace(replace(namingConvention, resourceToken, resourceAbbreviations.computeGallieries), '-', '_')
var diskEncryptionSetNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.diskEncryptionSets)
var diskNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.disks)
var firewallNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.azureFirewalls)
var firewallPolicyNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.firewallPolicies)
var ipConfigurationNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.ipConfigurations)
var keyVaultNamingConvention = '${replace(replace(namingConvention, resourceToken, resourceAbbreviations.keyVaults), '-', '')}unique_token'
var logAnalyticsWorkspaceNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.logAnalyticsWorkspaces)
var networkInterfaceNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.networkInterfaces)
var networkSecurityGroupNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.networkSecurityGroups)
var networkWatcherNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.networkWatchers)
var privateEndpointNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.privateEndpoints)
var privateLinkScopeName = replace(namingConvention, resourceToken, resourceAbbreviations.privateLinkScopes)
var publicIpAddressNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.publicIPAddresses)
var resourceGroupNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.resourceGroups)
var routeTableNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.routeTables)
var storageAccountNamingConvention = toLower('${replace(replace(namingConvention, resourceToken, resourceAbbreviations.storageAccounts), '-', '')}unique_token')
var subnetNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.subnets)
var userAssignedIdentityNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.userAssignedIdentities)
var virtualMachineNamingConvention = replace(replace(replace(namingConvention, resourceToken, resourceAbbreviations.virtualMachines), '-', ''), environmentAbbreviation, first(environmentAbbreviation))
var virtualNetworkNamingConvention = replace(namingConvention, resourceToken, resourceAbbreviations.virtualNetworks)

output resources object = {
  actionGroup: actionGroupNamingConvention
  automationAccount: automationAccountNamingConvention
  bastionHost: bastionHostNamingConvention
  computeGallery: computeGalleryNamingConvention
  diskEncryptionSet: diskEncryptionSetNamingConvention
  disk: diskNamingConvention
  firewall: firewallNamingConvention
  firewallPolicy: firewallPolicyNamingConvention
  ipConfiguration: ipConfigurationNamingConvention
  keyVault: keyVaultNamingConvention
  logAnalyticsWorkspace: logAnalyticsWorkspaceNamingConvention
  networkInterface: networkInterfaceNamingConvention
  networkSecurityGroup: networkSecurityGroupNamingConvention
  networkWatcher: networkWatcherNamingConvention
  privateEndpoint: privateEndpointNamingConvention
  privateLinkScope: privateLinkScopeName
  publicIpAddress: publicIpAddressNamingConvention
  resourceGroup: resourceGroupNamingConvention
  routeTable: routeTableNamingConvention
  storageAccount: storageAccountNamingConvention
  subnet: subnetNamingConvention
  userAssignedIdentity: userAssignedIdentityNamingConvention
  virtualMachine: virtualMachineNamingConvention
  virtualNetwork: virtualNetworkNamingConvention
}

output tokens object = {
  resource: resourceToken
  service: serviceToken
  network: networkToken
}
