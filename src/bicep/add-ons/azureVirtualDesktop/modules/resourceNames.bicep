targetScope = 'subscription'

param environmentShortName string
param identifier string
param locationControlPlane string
param locationVirtualMachines string
param stampIndex int

// NAMING CONVENTIONS
// All the resources are named using the following variables
// Modify the components of the naming convention to suit your needs
var resourceAbbreviation = 'resourceAbbreviation'
var serviceName = 'serviceName'
var networkName = 'avd'
var locationAbbreviation = 'locationAbbreviation'
var namingConvention = '${identifier}-${stampIndex}-${resourceAbbreviation}-${serviceName}-${networkName}-${environmentShortName}-${locationAbbreviation}'
var namingConvention_Global = '${resourceAbbreviation}-${serviceName}-${networkName}-${environmentShortName}-${locationAbbreviation}'
var namingConvention_Shared = '${identifier}-${resourceAbbreviation}-${serviceName}-${networkName}-${environmentShortName}-${locationAbbreviation}'

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
var automationAccountDiagnosticSettingName = replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diagnosticSettings), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var automationAccountName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.automationAccounts), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var automationAccountNetworkInterfaceName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, 'DSCAndHybridWorker-${resourceAbbreviations.automationAccounts}' ), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var automationAccountPrivateEndpointName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, 'DSCAndHybridWorker-${resourceAbbreviations.automationAccounts}' ), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var availabilitySetNamePrefix = '${replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.availabilitySets), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)}-'
var avdGlobalPrivateDnsZoneName = 'privatelink-global.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudEndpointSuffix}'
var avdPrivateDnsZoneName = 'privatelink.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudEndpointSuffix}'
var azureAutomationPrivateDnsZoneName = 'privatelink.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudEndpointSuffix}'
var backupPrivateDnsZoneName = 'privatelink.${locations[locationVirtualMachines].recoveryServicesGeo}.backup.${privateDnsZoneSuffixes_Backup[environment().name] ?? cloudEndpointSuffix}'
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var dataCollectionRuleAssociationName = '${replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.dataCollectionRuleAssociations), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)}-avdi'
var dataCollectionRuleName = 'microsoft-avdi-${locations[locationVirtualMachines].abbreviation}'
var desktopApplicationGroupName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.desktopApplicationGroups), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
var diskAccessName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diskAccesses), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var diskEncryptionSetName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diskEncryptionSets), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var diskNamePrefix = replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.disks), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
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
var hostPoolDiagnosticSettingName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diagnosticSettings), serviceName, resourceAbbreviations.hostPools), locationAbbreviation, locations[locationControlPlane].abbreviation)
var hostPoolName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.hostPools), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
var hostPoolNetworkInterfaceName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.hostPools), locationAbbreviation, locations[locationControlPlane].abbreviation)
var hostPoolPrivateEndpointName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.hostPools), locationAbbreviation, locations[locationControlPlane].abbreviation)
var keyVaultName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.keyVaults), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var keyVaultNetworkInterfaceName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.keyVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var keyVaultPrivateDnsZoneName = replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
var keyVaultPrivateEndpointName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.keyVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var logAnalyticsWorkspaceName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.logAnalyticsWorkspaces), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var netAppAccountName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.netAppAccounts), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var netAppCapacityPoolName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.netAppCapacityPools), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var networkInterfaceNamePrefix = replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var networkSecurityGroupNames = [
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkSecurityGroups), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkSecurityGroups), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
]
var monitorPrivateDnsZoneName = 'privatelink.monitor.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
var odsOpinsightsPrivateDnsZoneName = 'privatelink.ods.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
var omsOpinsightsPrivateDnsZoneName = 'privatelink.oms.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
var queuePrivateDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var recoveryServicesVaultName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.recoveryServicesVaults), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var recoveryServicesVaultNetworkInterfaceName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.recoveryServicesVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var recoveryServicesVaultPrivateEndpointName = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.recoveryServicesVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var resourceGroupControlPlane = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'controlPlane'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var resourceGroupFeedWorkspace = replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'feedWorkspace'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var resourceGroupGlobalWorkspace = replace(replace(replace(namingConvention_Global, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'globalWorkspace'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var resourceGroupHosts = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'sessionHosts'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var resourceGroupManagement = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'management'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var resourceGroupsNetwork = [
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'network'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'network'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
]
var resourceGroupStorage = replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'profileStorage'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var routeTables = [
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.routeTables), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.routeTables), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
]
var storageAccountNamePrefix = replace(replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.storageAccounts), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName)), '-', '')
var storageAccountNetworkInterfaceNamePrefix = replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.storageAccounts), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName))
var storageAccountPrivateEndpointNamePrefix = replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.storageAccounts), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName))
var userAssignedIdentityNamePrefix = replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.userAssignedIdentities), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
var virtualMachineNamePrefix = replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.virtualMachines), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentShortName, first(environmentShortName)), '-', '')
var virtualNetworkNames = [
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.virtualNetworks), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.virtualNetworks), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
]
var workspaceFeedDiagnosticSettingName = replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.diagnosticSettings), serviceName, 'feed-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var workspaceFeedName = replace(replace(replace(namingConvention_Shared, resourceAbbreviation, 'feed-${resourceAbbreviations.workspaces}'), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
var workspaceFeedNetworkInterfaceName = replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, 'feed-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var workspaceFeedPrivateEndpointName = replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, 'feed-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var workspaceGlobalName = replace(replace(replace(namingConvention_Global, resourceAbbreviation, 'global-${resourceAbbreviations.workspaces}'), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
var workspaceGlobalNetworkInterfaceName = replace(replace(replace(namingConvention_Global, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, 'global-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
var workspaceGlobalPrivateEndpointName = replace(replace(replace(namingConvention_Global, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, 'global-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)

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
output networkName string = networkName
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
output serviceName string = serviceName
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
