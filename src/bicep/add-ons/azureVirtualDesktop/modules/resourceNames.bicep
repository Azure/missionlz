targetScope = 'subscription'

param environmentShortName string
param identifier string
param locationControlPlane string
param locationVirtualMachines string
param stampIndex int

// NAMING CONVENTIONS
// All the resources are named using the following variables
// Modify the components of the naming convention to suit your needs
var namingConvention = '${identifier}-${stampIndex}-resourceType-${environmentShortName}-location'
var namingConvention_Global = 'resourceType-${environmentShortName}-location'
var namingConvention_Shared = '${identifier}-resourceType-${environmentShortName}-location'

// SUPPORTING DATA
var cloudEndpointSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var privateDnsZoneSuffixes_AzureAutomation = {
  AzureCloud: 'net'
  AzureUSGovernment: 'us'
}
var privateDnsZoneSuffixes_AzureVirtualDesktop = {
  AzureCloud: 'microsoft.com'
  AzureUSGovernment: 'azure.us'
}
var privateDnsZoneSuffixes_Backup = {
  AzureCloud: 'windowsazure.com'
  AzureUSGovernment: 'windowsazure.us'
}
var privateDnsZoneSuffixes_Monitor = {
  AzureCloud: 'azure.com'
  AzureUSGovernment: 'azure.us'
}
var locations = (loadJsonContent('../data/locations.json'))[environment().name]
var resourceAbbreviations = loadJsonContent('../data/resourceAbbreviations.json')

// RESOURCE NAMES AND PREFIXES

var agentSvcPrivateDnsZoneName = 'privatelink.agentsvc.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudEndpointSuffix}'
var automationAccountName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.automationAccounts), 'location', locations[locationVirtualMachines].abbreviation)
var availabilitySetNamePrefix = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.availabilitySets), 'location', locations[locationVirtualMachines].abbreviation)}-'
var avdGlobalPrivateDnsZoneName = 'privatelink-global.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudEndpointSuffix}'
var avdPrivateDnsZoneName = 'privatelink.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudEndpointSuffix}'
var azureAutomationPrivateDnsZoneName = 'privatelink.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudEndpointSuffix}'
var backupPrivateDnsZoneName = 'privatelink.${locations[locationVirtualMachines].recoveryServicesGeo}.backup.${privateDnsZoneSuffixes_Backup[environment().name] ?? cloudEndpointSuffix}'
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var dataCollectionRuleAssociationName = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.dataCollectionRuleAssociations), 'location', locations[locationVirtualMachines].abbreviation)}-avdi'
var dataCollectionRuleName = 'microsoft-avdi-${locations[locationVirtualMachines].abbreviation}'
var desktopApplicationGroupName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.desktopApplicationGroups), 'location', locations[locationControlPlane].abbreviation)
var diskAccessName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.diskAccesses), 'location', locations[locationVirtualMachines].abbreviation)
var diskEncryptionSetName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.diskEncryptionSets), 'location', locations[locationVirtualMachines].abbreviation)
var diskNamePrefix = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.disks), 'location', locations[locationVirtualMachines].abbreviation)}-'
var filePrivateDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'
var fileShareNames = {
  CloudCacheProfileContainer: [
    'profile-containers'
  ]
  CloudCacheProfileOfficeContainer: [
    'office-containers'
    'profile-containers'
  ]
  ProfileContainer: [
    'profile-containers'
  ]
  ProfileOfficeContainer: [
    'office-containers'
    'profile-containers'
  ]
}
var hostPoolName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.hostPools), 'location', locations[locationControlPlane].abbreviation)
var keyVaultName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.keyVaults), 'location', locations[locationVirtualMachines].abbreviation)
var keyVaultPrivateDnsZoneName = replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
var logAnalyticsWorkspaceName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.logAnalyticsWorkspaces), 'location', locations[locationVirtualMachines].abbreviation)
var netAppAccountName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.netAppAccounts), 'location', locations[locationVirtualMachines].abbreviation)
var netAppCapacityPoolName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.netAppCapacityPools), 'location', locations[locationVirtualMachines].abbreviation)
var networkInterfaceNamePrefix = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.networkInterfaces), 'location', locations[locationVirtualMachines].abbreviation)}-'
var networkSecurityGroupNames = [
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.networkSecurityGroups), 'location', locations[locationControlPlane].abbreviation)
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.networkSecurityGroups), 'location', locations[locationVirtualMachines].abbreviation)
]
var monitorPrivateDnsZoneName = 'privatelink.monitor.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
var odsOpinsightsPrivateDnsZoneName = 'privatelink.ods.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
var omsOpinsightsPrivateDnsZoneName = 'privatelink.oms.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
var queuePrivateDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var recoveryServicesVaultName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.recoveryServicesVaults), 'location', locations[locationVirtualMachines].abbreviation)
var resourceGroupControlPlane = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationControlPlane].abbreviation)}-avd-controlPlane'
var resourceGroupFeedWorkspace = '${replace(replace(namingConvention_Shared, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationControlPlane].abbreviation)}-avd-feedWorkspace'
var resourceGroupGlobalWorkspace = '${replace(replace(namingConvention_Global, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationControlPlane].abbreviation)}-avd-globalWorkspace'
var resourceGroupHosts = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationVirtualMachines].abbreviation)}-avd-sessionHosts'
var resourceGroupManagement = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationVirtualMachines].abbreviation)}-avd-management'
var resourceGroupsNetwork = [
  '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationControlPlane].abbreviation)}-avd-network'
  '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationVirtualMachines].abbreviation)}-avd-network'
]
var resourceGroupStorage = '${replace(replace(namingConvention, 'resourceType', resourceAbbreviations.resourceGroups), 'location', locations[locationVirtualMachines].abbreviation)}-avd-profileStorage'
var routeTables = [
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.routeTables), 'location', locations[locationControlPlane].abbreviation)
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.routeTables), 'location', locations[locationVirtualMachines].abbreviation)
]
var storageAccountNamePrefix = replace(replace(replace(replace(namingConvention, 'resourceType', resourceAbbreviations.storageAccounts), 'location', locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName)), '-', '')
var userAssignedIdentityNamePrefix = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.userAssignedIdentities), 'location', locations[locationVirtualMachines].abbreviation)
var virtualMachineNamePrefix = replace(replace(replace(replace(namingConvention, 'resourceType', resourceAbbreviations.virtualMachines), 'location', locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName)), '-', '')
var virtualNetworkNames = [
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.virtualNetworks), 'location', locations[locationControlPlane].abbreviation)
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.virtualNetworks), 'location', locations[locationVirtualMachines].abbreviation)
]
var workspaceFeedNamePrefix = replace(replace(namingConvention_Shared, 'resourceType', resourceAbbreviations.workspaces), 'location', locations[locationControlPlane].abbreviation)
var workspaceGlobalNamePrefix = replace(replace(namingConvention_Global, 'resourceType', resourceAbbreviations.workspaces), 'location', locations[locationControlPlane].abbreviation)

output agentSvcPrivateDnsZoneName string = agentSvcPrivateDnsZoneName
output automationAccountName string = automationAccountName
output availabilitySetNamePrefix string = availabilitySetNamePrefix
output avdGlobalPrivateDnsZoneName string = avdGlobalPrivateDnsZoneName
output avdPrivateDnsZoneName string = avdPrivateDnsZoneName
output azureAutomationPrivateDnsZoneName string = azureAutomationPrivateDnsZoneName
output backupPrivateDnsZoneName string = backupPrivateDnsZoneName
output blobPrivateDnsZoneName string = blobPrivateDnsZoneName
output dataCollectionRuleAssociationName string = dataCollectionRuleAssociationName
output dataCollectionRuleName string = dataCollectionRuleName
output desktopApplicationGroupName string = desktopApplicationGroupName
output diskAccessName string = diskAccessName
output diskEncryptionSetName string = diskEncryptionSetName
output diskNamePrefix string = diskNamePrefix
output filePrivateDnsZoneName string = filePrivateDnsZoneName
output fileShareNames object = fileShareNames
output hostPoolName string = hostPoolName
output keyVaultName string = keyVaultName
output keyVaultPrivateDnsZoneName string = keyVaultPrivateDnsZoneName
output locations object = locations
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName
output monitorPrivateDnsZoneName string = monitorPrivateDnsZoneName
output odsOpinsightsPrivateDnsZoneName string = odsOpinsightsPrivateDnsZoneName
output omsOpinsightsPrivateDnsZoneName string = omsOpinsightsPrivateDnsZoneName
output netAppAccountName string = netAppAccountName
output netAppCapacityPoolName string = netAppCapacityPoolName
output networkInterfaceNamePrefix string = networkInterfaceNamePrefix
output networkSecurityGroupNames array = networkSecurityGroupNames
output queuePrivateDnsZoneName string = queuePrivateDnsZoneName
output recoveryServicesVaultName string = recoveryServicesVaultName
output resourceAbbreviations object = resourceAbbreviations
output resourceGroupControlPlane string = resourceGroupControlPlane
output resourceGroupFeedWorkspace string = resourceGroupFeedWorkspace
output resourceGroupGlobalWorkspace string = resourceGroupGlobalWorkspace
output resourceGroupHosts string = resourceGroupHosts
output resourceGroupManagement string = resourceGroupManagement
output resourceGroupsNetwork array = resourceGroupsNetwork
output resourceGroupStorage string = resourceGroupStorage
output routeTables array = routeTables
output storageAccountNamePrefix string = storageAccountNamePrefix
output userAssignedIdentityNamePrefix string = userAssignedIdentityNamePrefix
output virtualMachineNamePrefix string = virtualMachineNamePrefix
output virtulNetworkNames array = virtualNetworkNames
output workspaceFeedNamePrefix string = workspaceFeedNamePrefix
output workspaceGlobalNamePrefix string = workspaceGlobalNamePrefix
