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
var locations = (loadJsonContent('../../../data/locations.json'))[environment().name]
var resourceAbbreviations = loadJsonContent('../../../data/resourceAbbreviations.json')

// RESOURCE NAMES AND PREFIXES

var agentSvcPrivateDnsZoneName = 'privatelink.agentsvc.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudEndpointSuffix}'
var automationAccountDiagnosticSettingName = replace(replace(namingConvention, 'resourceType', 'diag-${resourceAbbreviations.automationAccounts}'), 'location', locations[locationVirtualMachines].abbreviation)
var automationAccountName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.automationAccounts), 'location', locations[locationVirtualMachines].abbreviation)
var automationAccountNetworkInterfaceName = replace(replace(namingConvention, 'resourceType', 'nic-DSCAndHybridWorker-${resourceAbbreviations.automationAccounts}'), 'location', locations[locationVirtualMachines].abbreviation)
var automationAccountPrivateEndpointName = replace(replace(namingConvention, 'resourceType', 'pe-DSCAndHybridWorker-${resourceAbbreviations.automationAccounts}'), 'location', locations[locationVirtualMachines].abbreviation)
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
var hostPoolDiagnosticSettingName = replace(replace(namingConvention, 'resourceType', 'diag-${resourceAbbreviations.hostPools}'), 'location', locations[locationControlPlane].abbreviation)
var hostPoolName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.hostPools), 'location', locations[locationControlPlane].abbreviation)
var hostPoolNetworkInterfaceName = replace(replace(namingConvention, 'resourceType', 'nic-${resourceAbbreviations.hostPools}'), 'location', locations[locationControlPlane].abbreviation)
var hostPoolPrivateEndpointName = replace(replace(namingConvention, 'resourceType', 'pe-${resourceAbbreviations.hostPools}'), 'location', locations[locationControlPlane].abbreviation)
var keyVaultName = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.keyVaults), 'location', locations[locationVirtualMachines].abbreviation)
var keyVaultNetworkInterfaceName = replace(replace(namingConvention, 'resourceType', 'nic-${resourceAbbreviations.keyVaults}'), 'location', locations[locationVirtualMachines].abbreviation)
var keyVaultPrivateDnsZoneName = replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
var keyVaultPrivateEndpointName = replace(replace(namingConvention, 'resourceType', 'pe-${resourceAbbreviations.keyVaults}'), 'location', locations[locationVirtualMachines].abbreviation)
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
var recoveryServicesVaultNetworkInterfaceName = replace(replace(namingConvention, 'resourceType', 'nic-${resourceAbbreviations.recoveryServicesVaults}'), 'location', locations[locationVirtualMachines].abbreviation)
var recoveryServicesVaultPrivateEndpointName = replace(replace(namingConvention, 'resourceType', 'pe-${resourceAbbreviations.recoveryServicesVaults}'), 'location', locations[locationVirtualMachines].abbreviation)
var resourceGroupControlPlane = replace(replace(namingConvention, 'resourceType', '${resourceAbbreviations.resourceGroups}-controlPlane-avd'), 'location', locations[locationControlPlane].abbreviation)
var resourceGroupFeedWorkspace = replace(replace(namingConvention_Shared, 'resourceType', '${resourceAbbreviations.resourceGroups}-feedWorkspace-avd'), 'location', locations[locationControlPlane].abbreviation)
var resourceGroupGlobalWorkspace = replace(replace(namingConvention_Global, 'resourceType', '${resourceAbbreviations.resourceGroups}-globalWorkspace-avd'), 'location', locations[locationControlPlane].abbreviation)
var resourceGroupHosts = replace(replace(namingConvention, 'resourceType', '${resourceAbbreviations.resourceGroups}-sessionHosts-avd'), 'location', locations[locationVirtualMachines].abbreviation)
var resourceGroupManagement = replace(replace(namingConvention, 'resourceType', '${resourceAbbreviations.resourceGroups}-management-avd'), 'location', locations[locationVirtualMachines].abbreviation)
var resourceGroupsNetwork = [
  replace(replace(namingConvention, 'resourceType', '${resourceAbbreviations.resourceGroups}-network-avd'), 'location', locations[locationControlPlane].abbreviation)
  replace(replace(namingConvention, 'resourceType', '${resourceAbbreviations.resourceGroups}-network-avd'), 'location', locations[locationVirtualMachines].abbreviation)
]
var resourceGroupStorage = replace(replace(namingConvention, 'resourceType', '${resourceAbbreviations.resourceGroups}-profileStorage-avd'), 'location', locations[locationVirtualMachines].abbreviation)
var routeTables = [
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.routeTables), 'location', locations[locationControlPlane].abbreviation)
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.routeTables), 'location', locations[locationVirtualMachines].abbreviation)
]
var storageAccountNamePrefix = replace(replace(replace(replace(namingConvention, 'resourceType', resourceAbbreviations.storageAccounts), 'location', locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName)), '-', '')
var storageAccountNetworkInterfaceNamePrefix = replace(replace(replace(namingConvention, 'resourceType', 'nic-${resourceAbbreviations.storageAccounts}'), 'location', locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName))
var storageAccountPrivateEndpointNamePrefix = replace(replace(replace(namingConvention, 'resourceType', 'pe-${resourceAbbreviations.storageAccounts}'), 'location', locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName))
var userAssignedIdentityNamePrefix = replace(replace(namingConvention, 'resourceType', resourceAbbreviations.userAssignedIdentities), 'location', locations[locationVirtualMachines].abbreviation)
var virtualMachineNamePrefix = replace(replace(replace(replace(namingConvention, 'resourceType', resourceAbbreviations.virtualMachines), 'location', locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName)), '-', '')
var virtualNetworkNames = [
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.virtualNetworks), 'location', locations[locationControlPlane].abbreviation)
  replace(replace(namingConvention, 'resourceType', resourceAbbreviations.virtualNetworks), 'location', locations[locationVirtualMachines].abbreviation)
]
var workspaceFeedDiagnosticSettingName = replace(replace(namingConvention_Shared, 'resourceType', 'diag-feed-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)
var workspaceFeedName = replace(replace(namingConvention_Shared, 'resourceType', 'feed-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)
var workspaceFeedNetworkInterfaceName = replace(replace(namingConvention_Shared, 'resourceType', 'nic-feed-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)
var workspaceFeedPrivateEndpointName = replace(replace(namingConvention_Shared, 'resourceType', 'pe-feed-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)
var workspaceGlobalName = replace(replace(namingConvention_Global, 'resourceType', 'global-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)
var workspaceGlobalNetworkInterfaceName = replace(replace(namingConvention_Global, 'resourceType', 'nic-global-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)
var workspaceGlobalPrivateEndpointName = replace(replace(namingConvention_Global, 'resourceType', 'pe-global-${resourceAbbreviations.workspaces}'), 'location', locations[locationControlPlane].abbreviation)

output agentSvcPrivateDnsZoneName string = agentSvcPrivateDnsZoneName
output automationAccountDiagnosticSettingName string = automationAccountDiagnosticSettingName
output automationAccountName string = automationAccountName
output automationAccountNetworkInterfaceName string = automationAccountNetworkInterfaceName
output automationAccountPrivateEndpointName string = automationAccountPrivateEndpointName
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
output hostPoolDiagnosticSettingName string = hostPoolDiagnosticSettingName
output hostPoolName string = hostPoolName
output hostPoolNetworkInterfaceName string = hostPoolNetworkInterfaceName
output hostPoolPrivateEndpointName string = hostPoolPrivateEndpointName
output keyVaultName string = keyVaultName
output keyVaultNetworkInterfaceName string = keyVaultNetworkInterfaceName
output keyVaultPrivateDnsZoneName string = keyVaultPrivateDnsZoneName
output keyVaultPrivateEndpointName string = keyVaultPrivateEndpointName
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
output recoveryServicesVaultNetworkInterfaceName string = recoveryServicesVaultNetworkInterfaceName
output recoveryServicesVaultPrivateEndpointName string = recoveryServicesVaultPrivateEndpointName
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
output storageAccountNetworkInterfaceNamePrefix string = storageAccountNetworkInterfaceNamePrefix
output storageAccountPrivateEndpointNamePrefix string = storageAccountPrivateEndpointNamePrefix
output userAssignedIdentityNamePrefix string = userAssignedIdentityNamePrefix
output virtualMachineNamePrefix string = virtualMachineNamePrefix
output virtulNetworkNames array = virtualNetworkNames
output workspaceFeedDiagnosticSettingName string = workspaceFeedDiagnosticSettingName
output workspaceFeedName string = workspaceFeedName
output workspaceFeedNetworkInterfaceName string = workspaceFeedNetworkInterfaceName
output workspaceFeedPrivateEndpointName string = workspaceFeedPrivateEndpointName
output workspaceGlobalName string = workspaceGlobalName
output workspaceGlobalNetworkInterfaceName string = workspaceGlobalNetworkInterfaceName
output workspaceGlobalPrivateEndpointName string = workspaceGlobalPrivateEndpointName
