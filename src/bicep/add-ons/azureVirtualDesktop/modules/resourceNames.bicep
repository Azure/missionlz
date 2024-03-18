targetScope = 'subscription'

param environmentAbbreviation string
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
var namingConvention = '${identifier}-${stampIndex}-${resourceAbbreviation}-${serviceName}-${networkName}-${environmentAbbreviation}-${locationAbbreviation}'
var namingConvention_Global = '${resourceAbbreviation}-${serviceName}-${networkName}-${environmentAbbreviation}-${locationAbbreviation}'
var namingConvention_Shared = '${identifier}-${resourceAbbreviation}-${serviceName}-${networkName}-${environmentAbbreviation}-${locationAbbreviation}'

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
var resources = {
  agentSvcPrivateDnsZoneName: 'privatelink.agentsvc.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudEndpointSuffix}'
  automationAccountDiagnosticSettingName: replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diagnosticSettings), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  automationAccountName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.automationAccounts), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  automationAccountNetworkInterfaceName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, 'DSCAndHybridWorker-${resourceAbbreviations.automationAccounts}' ), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  automationAccountPrivateEndpointName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, 'DSCAndHybridWorker-${resourceAbbreviations.automationAccounts}' ), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  availabilitySetNamePrefix: '${replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.availabilitySets), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)}-'
  avdGlobalPrivateDnsZoneName: 'privatelink-global.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudEndpointSuffix}'
  avdPrivateDnsZoneName: 'privatelink.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[environment().name] ?? cloudEndpointSuffix}'
  azureAutomationPrivateDnsZoneName: 'privatelink.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudEndpointSuffix}'
  backupPrivateDnsZoneName: 'privatelink.${locations[locationVirtualMachines].recoveryServicesGeo}.backup.${privateDnsZoneSuffixes_Backup[environment().name] ?? cloudEndpointSuffix}'
  blobPrivateDnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
  dataCollectionRuleAssociationName: '${replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.dataCollectionRuleAssociations), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)}-avdi'
  dataCollectionRuleName: 'microsoft-avdi-${locations[locationVirtualMachines].abbreviation}'
  desktopApplicationGroupName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.desktopApplicationGroups), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  diskAccessName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diskAccesses), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  diskEncryptionSetName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diskEncryptionSets), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  diskNamePrefix: replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.disks), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  filePrivateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
  fileShareNames: {
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
  hostPoolDiagnosticSettingName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.diagnosticSettings), serviceName, resourceAbbreviations.hostPools), locationAbbreviation, locations[locationControlPlane].abbreviation)
  hostPoolName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.hostPools), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  hostPoolNetworkInterfaceName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.hostPools), locationAbbreviation, locations[locationControlPlane].abbreviation)
  hostPoolPrivateEndpointName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.hostPools), locationAbbreviation, locations[locationControlPlane].abbreviation)
  keyVaultName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.keyVaults), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  keyVaultNetworkInterfaceName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.keyVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  keyVaultPrivateDnsZoneName: replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore')
  keyVaultPrivateEndpointName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.keyVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  logAnalyticsWorkspaceName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.logAnalyticsWorkspaces), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  netAppAccountName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.netAppAccounts), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  netAppCapacityPoolName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.netAppCapacityPools), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  networkInterfaceNamePrefix: replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  networkSecurityGroupNames: [
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkSecurityGroups), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkSecurityGroups), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  ]
  monitorPrivateDnsZoneName: 'privatelink.monitor.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
  odsOpinsightsPrivateDnsZoneName: 'privatelink.ods.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
  omsOpinsightsPrivateDnsZoneName: 'privatelink.oms.opinsights.${privateDnsZoneSuffixes_Monitor[environment().name] ?? cloudEndpointSuffix}'
  queuePrivateDnsZoneName: 'privatelink.queue.${environment().suffixes.storage}'
  recoveryServicesVaultName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.recoveryServicesVaults), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  recoveryServicesVaultNetworkInterfaceName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.recoveryServicesVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  recoveryServicesVaultPrivateEndpointName: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.recoveryServicesVaults), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  resourceGroupControlPlane: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'controlPlane'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  resourceGroupFeedWorkspace: replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'feedWorkspace'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  resourceGroupGlobalWorkspace: replace(replace(replace(namingConvention_Global, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'globalWorkspace'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  resourceGroupHosts: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'sessionHosts'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  resourceGroupManagement: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'management'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  resourceGroupsNetwork: [
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'network'), locationAbbreviation, locations[locationControlPlane].abbreviation)
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'network'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  ]
  resourceGroupStorage: replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.resourceGroups), serviceName, 'profileStorage'), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  routeTableNames: [
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.routeTables), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.routeTables), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  ]
  storageAccountNamePrefix: replace(replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.storageAccounts), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentAbbreviation, first(environmentAbbreviation)), '-', '')
  storageAccountNetworkInterfaceNamePrefix: replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, resourceAbbreviations.storageAccounts), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentAbbreviation, first(environmentAbbreviation))
  storageAccountPrivateEndpointNamePrefix: replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, resourceAbbreviations.storageAccounts), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentAbbreviation, first(environmentAbbreviation))
  userAssignedIdentityNamePrefix: replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.userAssignedIdentities), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  virtualMachineNamePrefix: replace(replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.virtualMachines), locationAbbreviation, locations[locationVirtualMachines].abbreviation), environmentAbbreviation, first(environmentAbbreviation)), '-', '')
  virtualNetworkNames: [
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.virtualNetworks), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
    replace(replace(replace(namingConvention, resourceAbbreviation, resourceAbbreviations.virtualNetworks), '-${serviceName}', ''), locationAbbreviation, locations[locationVirtualMachines].abbreviation)
  ]
  workspaceFeedDiagnosticSettingName: replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.diagnosticSettings), serviceName, 'feed-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceFeedName: replace(replace(replace(namingConvention_Shared, resourceAbbreviation, 'feed-${resourceAbbreviations.workspaces}'), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceFeedNetworkInterfaceName: replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, 'feed-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceFeedPrivateEndpointName: replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, 'feed-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceFriendlyName: replace(replace(replace(namingConvention_Shared, resourceAbbreviation, resourceAbbreviations.workspaces), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceGlobalName: replace(replace(replace(namingConvention_Global, resourceAbbreviation, 'global-${resourceAbbreviations.workspaces}'), '-${serviceName}', ''), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceGlobalNetworkInterfaceName: replace(replace(replace(namingConvention_Global, resourceAbbreviation, resourceAbbreviations.networkInterfaces), serviceName, 'global-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
  workspaceGlobalPrivateEndpointName: replace(replace(replace(namingConvention_Global, resourceAbbreviation, resourceAbbreviations.privateEndpoints), serviceName, 'global-${resourceAbbreviations.workspaces}'), locationAbbreviation, locations[locationControlPlane].abbreviation)
}

output locations object = locations
output networkName string = networkName
output resources object = resources
output serviceName string = serviceName
