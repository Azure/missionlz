targetScope = 'subscription'

@allowed([
  'ActiveDirectoryDomainServices'
  'MicrosoftEntraDomainServices'
  'MicrosoftEntraId'
  'MicrosoftEntraIdIntuneEnrollment'
])
@description('The service providing domain services for Azure Virtual Desktop.  This is needed to properly configure the session hosts and if applicable, the Azure Storage Account.')
param activeDirectorySolution string

@description('The name of the Azure Blobs container hosting the required artifacts.')
param artifactsContainerName string

@description('The resource ID for the storage account hosting the artifacts in Blob storage.')
param artifactsStorageAccountResourceId string

@allowed([
  'AvailabilitySets'
  'AvailabilityZones'
  'None'
])
@description('The desired availability option when deploying a pooled host pool. The best practice is to deploy to availability zones for the highest resilency and service level agreement.')
param availability string = 'AvailabilityZones'

@description('The blob name of the MSI file for the AVD Agent installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param avdAgentMsiName string

@description('The blob name of the MSI file for the AVD Agent Boot Loader installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param avdAgentBootLoaderMsiName string

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

@description('The subnet address prefix for the Azure NetApp Files delegated subnet.')
param azureNetAppFilesSubnetAddressPrefix string = ''

@description('The blob name of the MSI file for the  Azure PowerShell Module installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param azurePowerShellModuleMsiName string

@description('The RDP properties to add or remove RDP functionality on the AVD host pool. The string must end with a semi-colon. Settings reference: https://learn.microsoft.com/windows-server/remote/remote-desktop-services/clients/rdp-files')
param customRdpProperty string = 'audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;'

@description('The friendly name for the Desktop application in the desktop application group.')
param desktopFriendlyName string = ''

@description('Disabling BGP route propagation is a route table configuration that prevents the propagation of on-premises routes to network interfaces in the associated subnets.')
param disableBgpRoutePropagation bool = true

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
@description('The storage SKU for the managed disks on the AVD session hosts. Production deployments should use Premium_LRS.')
param diskSku string = 'Premium_LRS'

@secure()
@description('The password for the account to domain join the AVD session hosts.')
param domainJoinPassword string = ''

@description('The user principal name for the account to domain join the AVD session hosts.')
param domainJoinUserPrincipalName string = ''

@description('The name of the domain that provides ADDS to the AVD session hosts.')
param domainName string = ''

@description('The drain mode option enables drain mode for the sessions hosts in this deployment to prevent users from accessing the hosts until they have been validated.')
param drainMode bool = false

@allowed([
  'dev' // Development
  'prod' // Production
  'test' // Test
])
@description('The short name for the target environment.')
param environmentShortName string = 'dev'

@description('The file share size(s) in GB for the Fslogix storage solution.')
param fslogixShareSizeInGB int = 100

@allowed([
  'CloudCacheProfileContainer' // FSLogix Cloud Cache Profile Container
  'CloudCacheProfileOfficeContainer' // FSLogix Cloud Cache Profile & Office Container
  'ProfileContainer' // FSLogix Profile Container
  'ProfileOfficeContainer' // FSLogix Profile & Office Container
])
@description('If deploying FSLogix, select the desired type of container for user profiles. https://learn.microsoft.com/en-us/fslogix/concepts-container-types')
param fslogixContainerType string = 'ProfileContainer'

@allowed([
  'AzureNetAppFiles Premium' // ANF with the Premium SKU, 450,000 IOPS
  'AzureNetAppFiles Standard' // ANF with the Standard SKU, 320,000 IOPS
  'AzureFiles Premium' // Azure Files Premium with a Private Endpoint, 100,000 IOPS
  'AzureFiles Standard' // Azure Files Standard with the Large File Share option and a Private Endpoint, 20,000 IOPS
  'None'
])
@description('Enable an Fslogix storage option to manage user profiles for the AVD session hosts. The selected service & SKU should provide sufficient IOPS for all of your users. https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#performance-requirements')
param fslogixStorageService string = 'AzureFiles Standard'

@allowed([
  'Disabled'
  'Enabled'
  'EnabledForClientsOnly'
  'EnabledForSessionHostsOnly'
])
@description('The type of public network access for the host pool.')
param hostPoolPublicNetworkAccess string

@allowed([
  'Pooled DepthFirst'
  'Pooled BreadthFirst'
  'Personal Automatic'
  'Personal Direct'
])
@description('These options specify the host pool type and depending on the type provides the load balancing options and assignment types.')
param hostPoolType string = 'Pooled DepthFirst'

@description('The resource ID for the Azure Firewall in the HUB subscription')
param hubAzureFirewallResourceId string

@description('The resource ID for the subnet in the Shared Services subscription. This is required for the private endpoint on the AVD Global Workspace.')
param hubSubnetResourceId string

@description('The resource ID for the Azure Virtual Network in the HUB subscription.')
param hubVirtualNetworkResourceId string

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param identifier string = 'avd'

@description('The resource ID for the Compute Gallery Image Version. Do not set this value if using a marketplace image.')
param imageDefinitionResourceId string = ''

@description('Offer for the virtual machine image')
param imageOffer string = 'office-365'

@description('Publisher for the virtual machine image')
param imagePublisher string = 'MicrosoftWindowsDesktop'

@description('SKU for the virtual machine image')
param imageSku string = 'win11-22h2-avd-m365'

@description('The deployment location for the AVD management resources.')
param locationControlPlane string = deployment().location

@description('The deployment location for the AVD sessions hosts.')
param locationVirtualMachines string = deployment().location

@maxValue(730)
@minValue(30)
@description('The retention for the Log Analytics Workspace to setup the AVD monitoring solution')
param logAnalyticsWorkspaceRetention int = 30

@allowed([
  'Free'
  'Standard'
  'Premium'
  'PerNode'
  'PerGB2018'
  'Standalone'
  'CapacityReservation'
])
@description('The SKU for the Log Analytics Workspace to setup the AVD monitoring solution')
param logAnalyticsWorkspaceSku string = 'PerGB2018'

@description('The maximum number of sessions per AVD session host.')
param maxSessionLimit int

@description('Deploys the required monitoring resources to enable AVD Insights and monitor features in the automation account.')
param monitoring bool = true

@description('The distinguished name for the target Organization Unit in Active Directory Domain Services.')
param organizationalUnitPath string = ''

@description('Enable backups to an Azure Recovery Services vault.  For a pooled host pool this will enable backups on the Azure file share.  For a personal host pool this will enable backups on the AVD sessions hosts.')
param recoveryServices bool = false

@description('The time when session hosts will scale up and continue to stay on to support peak demand; Format 24 hours e.g. 9:00 for 9am')
param scalingBeginPeakTime string = '9:00'

@description('The time when session hosts will scale down and stay off to support low demand; Format 24 hours e.g. 17:00 for 5pm')
param scalingEndPeakTime string = '17:00'

@description('The number of seconds to wait before automatically signing out users. If set to 0 any session host that has user sessions will be left untouched')
param scalingLimitSecondsToForceLogOffUser string = '0'

@description('The minimum number of session host VMs to keep running during off-peak hours. The scaling tool will not work if all virtual machines are turned off and the Start VM On Connect solution is not enabled.')
param scalingMinimumNumberOfRdsh string = '0'

@description('The maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours')
param scalingSessionThresholdPerCPU string = '1'

@description('Deploys the required resources for the Scaling Tool. https://docs.microsoft.com/en-us/azure/virtual-desktop/scaling-automation-logic-apps')
param scalingTool bool = false

@description('The resource ID of the log analytics workspace used for Azure Sentinel and / or Defender for Cloud. When using the Microsoft monitoring Agent, this allows you to multihome the agent to reduce unnecessary log collection and reduce cost.')
param securityLogAnalyticsWorkspaceResourceId string = ''

@description('The array of Security Principals with their object IDs and display names to assign to the AVD Application Group and FSLogix Storage.')
param securityPrincipals array

@maxValue(5000)
@minValue(0)
@description('The number of session hosts to deploy in the host pool. Ensure you have the approved quota to deploy the desired count.')
param sessionHostCount int = 1

@maxValue(4999)
@minValue(0)
@description('The starting number for the session hosts. This is important when adding virtual machines to ensure an update deployment is not performed on an existing, active session host.')
param sessionHostIndex int = 0

@maxValue(9)
@minValue(0)
@description('The stamp index allows for multiple AVD stamps with the same business unit or project to support different use cases. For example, "0" could be used for an office workers host pool and "1" could be used for a developers host pool within the "finance" business unit.')
param stampIndex int = 0

@maxValue(100)
@minValue(0)
@description('The number of storage accounts to deploy to support sharding across multiple storage accounts. https://docs.microsoft.com/en-us/azure/architecture/patterns/sharding')
param storageCount int = 1

@maxValue(99)
@minValue(0)
@description('The starting number for the names of the storage accounts to support sharding across multiple storage accounts. https://docs.microsoft.com/en-us/azure/architecture/patterns/sharding')
param storageIndex int = 0

@description('The address prefix(es) for the new subnet(s) that will be created in the spoke virtual network(s).')
param subnetAddressPrefixes array

@description('The Key / value pairs of metadata for the Azure resource groups and resources.')
param tags object = {}

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param timestamp string = utcNow('yyyyMMddhhmmss')

@description('The validation environment setting on the AVD host pool determines whether the hostpool should receive AVD preview features for testing.')
param validationEnvironment bool = false

@allowed([
  'AzureMonitorAgent'
  'LogAnalyticsAgent'
])
@description('Input the desired monitoring agent to send events and performance counters to a log analytics workspace.')
param virtualMachineMonitoringAgent string = 'LogAnalyticsAgent'

@secure()
@description('The local administrator password for the AVD session hosts')
param virtualMachinePassword string

@description('The virtual machine SKU for the AVD session hosts.')
param virtualMachineSize string = 'Standard_D4ads_v5'

@description('The local administrator username for the AVD session hosts')
param virtualMachineUsername string

@description('The address prefix for the new spoke virtual network(s).')
param virtualNetworkAddressPrefixes array

@description('The friendly name for the AVD workspace that is displayed in the end-user client.')
param workspaceFriendlyName string = ''

@allowed([
  'Disabled'
  'Enabled'
])
@description('The public network access setting on the AVD workspace either disables public network access or allows both public and private network access.')
param workspacePublicNetworkAccess string

var artifactsUri = 'https://${artifactsStorageAccountName}.blob.${environment().suffixes.storage}/${artifactsContainerName}/'
var artifactsStorageAccountName = split(artifactsStorageAccountResourceId, '/')[8]
var privateDnsZoneResourceIdPrefix = '/subscriptions/${split(hubVirtualNetworkResourceId, '/')[2]}/resourceGroups/${split(hubVirtualNetworkResourceId, '/')[4]}/providers/Microsoft.Network/privateDnsZones/'
var deploymentLocations = union([
  locationControlPlane
], [
  locationVirtualMachines
])
var resourceGroupsCount = 4 + length(deploymentLocations) + (fslogixStorageService == 'None' ? 0 : 1)

// Resource Names
module resourceNames 'modules/resourceNames.bicep' = {
  name: 'ResourceNames_${timestamp}'
  params: {
    environmentShortName: environmentShortName
    identifier: identifier
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    stampIndex: stampIndex
  }
}

// Logic
module logic 'modules/logic.bicep' = {
  name: 'Logic_${timestamp}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    deploymentLocations: deploymentLocations
    diskSku: diskSku
    domainName: domainName
    fileShareNames: resourceNames.outputs.fileShareNames
    fslogixContainerType: fslogixContainerType
    fslogixStorageService: fslogixStorageService
    hostPoolType: hostPoolType
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    locations: resourceNames.outputs.locations
    locationVirtualMachines: locationVirtualMachines
    resourceGroupControlPlane: resourceNames.outputs.resourceGroupControlPlane
    resourceGroupFeedWorkspace: resourceNames.outputs.resourceGroupFeedWorkspace
    resourceGroupHosts: resourceNames.outputs.resourceGroupHosts
    resourceGroupManagement: resourceNames.outputs.resourceGroupManagement
    resourceGroupsNetwork: resourceNames.outputs.resourceGroupsNetwork
    resourceGroupStorage: resourceNames.outputs.resourceGroupStorage
    securityPrincipals: securityPrincipals
    sessionHostCount: sessionHostCount
    sessionHostIndex: sessionHostIndex
    virtualMachineNamePrefix: resourceNames.outputs.virtualMachineNamePrefix
    virtualMachineSize: virtualMachineSize
  }
}

// Resource Groups
module rgs 'modules/resourceGroup.bicep' = [for i in range(0, resourceGroupsCount): {
  name: 'ResourceGroup_${i}_${timestamp}'
  params: {
    location: contains(logic.outputs.resourceGroups[i], 'controlPlane') || contains(logic.outputs.resourceGroups[i], 'feedWorkspace') ? locationControlPlane : locationVirtualMachines
    resourceGroupName: logic.outputs.resourceGroups[i]
    tags: tags
  }
}]

module network_controlPlane 'modules/network/networking.bicep' =  {
  name: 'Network_ControlPlane_${timestamp}'
  params: {
    azureNetAppFilesSubnetAddressPrefix: !empty(azureNetAppFilesSubnetAddressPrefix) && length(deploymentLocations) == 1 ? azureNetAppFilesSubnetAddressPrefix : ''
    disableBgpRoutePropagation: disableBgpRoutePropagation
    hubAzureFirewallResourceId: hubAzureFirewallResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    index: 0
    location: deploymentLocations[0]
    networkSecurityGroupName: resourceNames.outputs.networkSecurityGroupNames[0]
    resourceGroupNetwork: resourceNames.outputs.resourceGroupsNetwork[0]
    routeTableName: resourceNames.outputs.routeTables[0]
    subnetAddressPrefixes: subnetAddressPrefixes
    timestamp: timestamp
    virtualNetworkAddressPrefixes: virtualNetworkAddressPrefixes
    virtualNetworkName: resourceNames.outputs.virtulNetworkNames[0]
  }
  dependsOn: [
    rgs
  ]
}

module network_hosts 'modules/network/networking.bicep' = if (length(deploymentLocations) == 2) {
  name: 'Network_Hosts_${timestamp}'
  params: {
    azureNetAppFilesSubnetAddressPrefix: !empty(azureNetAppFilesSubnetAddressPrefix) && length(deploymentLocations) == 2 ? azureNetAppFilesSubnetAddressPrefix : ''
    disableBgpRoutePropagation: disableBgpRoutePropagation
    hubAzureFirewallResourceId: hubAzureFirewallResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    index: 1
    location: deploymentLocations[1]
    networkSecurityGroupName: resourceNames.outputs.networkSecurityGroupNames[1]
    resourceGroupNetwork: length(deploymentLocations) == 1 ? resourceNames.outputs.resourceGroupsNetwork[0] : resourceNames.outputs.resourceGroupsNetwork[1]
    routeTableName: resourceNames.outputs.routeTables[1]
    subnetAddressPrefixes: subnetAddressPrefixes
    timestamp: timestamp
    virtualNetworkAddressPrefixes: virtualNetworkAddressPrefixes
    virtualNetworkName: resourceNames.outputs.virtulNetworkNames[1]
  }
  dependsOn: [
    rgs
  ]
}

// Management Services: Logging, Automation, Keys, Encryption
module management 'modules/management/management.bicep' = {
  name: 'Management_${timestamp}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    artifactsStorageAccountResourceId: artifactsStorageAccountResourceId
    artifactsUri: artifactsUri
    automationAccountName: resourceNames.outputs.automationAccountName
    automationAccountPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.azureAutomationPrivateDnsZoneName}'
    availability: availability
    avdObjectId: avdObjectId
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.blobPrivateDnsZoneName}'
    azurePowerShellModuleMsiName: azurePowerShellModuleMsiName 
    azureQueueStoragePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.queuePrivateDnsZoneName}'
    dataCollectionRuleName: resourceNames.outputs.dataCollectionRuleName
    //diskAccessName: resourceNames.outputs.diskAccessName
    diskEncryptionSetName: resourceNames.outputs.diskEncryptionSetName
    diskNamePrefix: resourceNames.outputs.diskNamePrefix
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableMonitoring: monitoring
    environmentShortName: environmentShortName
    fslogix: logic.outputs.fslogix
    fslogixStorageService: fslogixStorageService
    hostPoolName: resourceNames.outputs.hostPoolName
    hostPoolType: hostPoolType
    imageDefinitionResourceId: imageDefinitionResourceId
    keyVaultAbbreviation: resourceNames.outputs.resourceAbbreviations.keyVaults
    keyVaultName: resourceNames.outputs.keyVaultName
    keyVaultPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.keyVaultPrivateDnsZoneName}'
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceName: resourceNames.outputs.logAnalyticsWorkspaceName
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    networkInterfaceNamePrefix: resourceNames.outputs.networkInterfaceNamePrefix
    organizationalUnitPath: organizationalUnitPath
    recoveryServices: recoveryServices
    recoveryServicesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.backupPrivateDnsZoneName}'
    recoveryServicesVaultName: resourceNames.outputs.recoveryServicesVaultName
    resourceGroupControlPlane: resourceNames.outputs.resourceGroupControlPlane
    resourceGroupFeedWorkspace: resourceNames.outputs.resourceGroupFeedWorkspace
    resourceGroupHosts: resourceNames.outputs.resourceGroupHosts
    resourceGroupManagement: resourceNames.outputs.resourceGroupManagement
    resourceGroupStorage: resourceNames.outputs.resourceGroupStorage
    roleDefinitions: logic.outputs.roleDefinitions
    scalingTool: scalingTool
    securityLogAnalyticsWorkspaceResourceId: securityLogAnalyticsWorkspaceResourceId
    sessionHostCount: sessionHostCount
    storageService: logic.outputs.storageService
    subnetResourceId: length(deploymentLocations) == 1 ? network_controlPlane.outputs.subnetResourceId : network_hosts.outputs.subnetResourceId
    tags: tags
    timestamp: timestamp
    timeZone: logic.outputs.timeZone
    userAssignedIdentityNamePrefix: resourceNames.outputs.userAssignedIdentityNamePrefix
    virtualMachineMonitoringAgent: virtualMachineMonitoringAgent
    virtualMachineNamePrefix: resourceNames.outputs.virtualMachineNamePrefix
    virtualMachinePassword: virtualMachinePassword
    virtualMachineSize: virtualMachineSize
    virtualMachineUsername: virtualMachineUsername
    workspaceNamePrefix: resourceNames.outputs.workspaceFeedNamePrefix
  }
  dependsOn: [
    rgs
  ]
}

// Global AVD Worksspace
// This module creates the global AVD workspace to support AVD with Private Link
module hub 'modules/hub/hub.bicep' = {
  name: 'Hub_${timestamp}'
  scope: subscription(split(hubSubnetResourceId, '/')[2])
  params: {
    existingWorkspace: management.outputs.existingFeedWorkspace
    globalWorkspacePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.avdGlobalPrivateDnsZoneName}'
    hubSubnetResourceId: hubSubnetResourceId
    resourceGroupName: resourceNames.outputs.resourceGroupGlobalWorkspace
    timestamp: timestamp
    workspaceNamePrefix: resourceNames.outputs.workspaceGlobalNamePrefix
  }
}

// AVD Control Plane
// This module deploys the host pool and desktop application group
module controlPlane 'modules/controlPlane/controlPlane.bicep' = {
  name: 'ControlPlane_${timestamp}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    artifactsUri: artifactsUri
    avdPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.avdPrivateDnsZoneName}'
    customRdpProperty: customRdpProperty
    deploymentUserAssignedIdentityClientId: management.outputs.deploymentUserAssignedIdentityClientId
    desktopApplicationGroupName: resourceNames.outputs.desktopApplicationGroupName
    desktopFriendlyName: desktopFriendlyName
    existingFeedWorkspace: management.outputs.existingFeedWorkspace
    hostPoolName: resourceNames.outputs.hostPoolName
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: monitoring ? management.outputs.logAnalyticsWorkspaceResourceId : ''
    managementVirtualMachineName: management.outputs.virtualMachineName
    maxSessionLimit: maxSessionLimit
    monitoring: monitoring
    resourceGroupControlPlane: resourceNames.outputs.resourceGroupControlPlane
    resourceGroupFeedWorkspace: resourceNames.outputs.resourceGroupFeedWorkspace
    resourceGroupManagement: resourceNames.outputs.resourceGroupManagement
    roleDefinitions: logic.outputs.roleDefinitions
    securityPrincipalObjectIds: map(securityPrincipals, item => item.objectId)
    subnetResourceId: network_controlPlane.outputs.subnetResourceId
    tags: tags 
    timestamp: timestamp
    validationEnvironment: validationEnvironment
    vmTemplate: logic.outputs.vmTemplate
    workspaceFriendlyName: workspaceFriendlyName
    workspaceNamePrefix: resourceNames.outputs.workspaceFeedNamePrefix
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
  dependsOn: [
    rgs
  ]
}

module fslogix 'modules/fslogix/fslogix.bicep' = {
  name: 'FSLogix_${timestamp}'
  params: {
    activeDirectoryConnection: management.outputs.validateANFfActiveDirectory
    activeDirectorySolution: activeDirectorySolution
    artifactsUri: artifactsUri
    automationAccountName: resourceNames.outputs.automationAccountName
    availability: availability
    azureFilesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${resourceNames.outputs.filePrivateDnsZoneName}'
    delegatedSubnetId: management.outputs.validateANFSubnetId
    deploymentUserAssignedIdentityClientId: management.outputs.deploymentUserAssignedIdentityClientId
    dnsServers: management.outputs.validateANFDnsServers
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    encryptionUserAssignedIdentityResourceId: management.outputs.encryptionUserAssignedIdentityResourceId
    fileShares: logic.outputs.fileShares
    fslogixContainerType: fslogixContainerType
    fslogixShareSizeInGB: fslogixShareSizeInGB
    fslogixStorageService: fslogixStorageService
    hostPoolName: resourceNames.outputs.hostPoolName
    hostPoolType: hostPoolType
    keyVaultUri: management.outputs.keyVaultUri
    location: locationVirtualMachines
    managementVirtualMachineName: management.outputs.virtualMachineName
    netAppAccountName: resourceNames.outputs.netAppAccountName
    netAppCapacityPoolName: resourceNames.outputs.netAppCapacityPoolName
    netbios: logic.outputs.netbios
    organizationalUnitPath: organizationalUnitPath
    recoveryServices: recoveryServices
    recoveryServicesVaultName: resourceNames.outputs.recoveryServicesVaultName
    resourceGroupControlPlane: resourceNames.outputs.resourceGroupControlPlane
    resourceGroupManagement: resourceNames.outputs.resourceGroupManagement
    resourceGroupStorage: resourceNames.outputs.resourceGroupStorage
    securityPrincipalNames: map(securityPrincipals, item => item.name)
    securityPrincipalObjectIds: map(securityPrincipals, item => item.objectId)
    smbServerLocation: logic.outputs.smbServerLocation
    storageAccountNamePrefix: resourceNames.outputs.storageAccountNamePrefix
    storageCount: storageCount
    storageEncryptionKeyName: management.outputs.storageEncryptionKeyName
    storageIndex: storageIndex
    storageService: logic.outputs.storageService
    storageSku: logic.outputs.storageSku
    subnet: length(deploymentLocations) == 1 ? split(network_controlPlane.outputs.subnetResourceId, '/')[10] : split(network_hosts.outputs.subnetResourceId, '/')[10]
    tags: tags
    timestamp: timestamp
    timeZone: logic.outputs.timeZone
    virtualNetwork: length(deploymentLocations) == 1 ? split(network_controlPlane.outputs.subnetResourceId, '/')[8] : split(network_hosts.outputs.subnetResourceId, '/')[8]
    virtualNetworkResourceGroup: length(deploymentLocations) == 1 ? split(network_controlPlane.outputs.subnetResourceId, '/')[4] : split(network_hosts.outputs.subnetResourceId, '/')[4]
  }
  dependsOn: [
    controlPlane
    rgs
  ]
}

module sessionHosts 'modules/sessionHosts/sessionHosts.bicep' = {
  name: 'SessionHosts_${timestamp}'
  params: {
    acceleratedNetworking: management.outputs.validateAcceleratedNetworking
    activeDirectorySolution: activeDirectorySolution
    artifactsUri: artifactsUri
    artifactsUserAssignedIdentityClientId: management.outputs.artifactsUserAssignedIdentityClientId
    artifactsUserAssignedIdentityResourceId: management.outputs.artifactsUserAssignedIdentityResourceId
    automationAccountName: resourceNames.outputs.automationAccountName
    availability: availability
    availabilitySetNamePrefix: resourceNames.outputs.availabilitySetNamePrefix
    availabilitySetsCount: logic.outputs.availabilitySetsCount
    availabilitySetsIndex: logic.outputs.beginAvSetRange
    availabilityZones: management.outputs.validateAvailabilityZones
    avdAgentBootLoaderMsiName: avdAgentBootLoaderMsiName
    avdAgentMsiName: avdAgentMsiName
    dataCollectionRuleAssociationName: resourceNames.outputs.dataCollectionRuleAssociationName
    dataCollectionRuleResourceId: management.outputs.dataCollectionRuleResourceId
    deploymentUserAssignedIdentityClientId: management.outputs.deploymentUserAssignedIdentityClientId
    diskEncryptionSetResourceId: management.outputs.diskEncryptionSetResourceId
    diskNamePrefix: resourceNames.outputs.diskNamePrefix
    diskSku: diskSku
    divisionRemainderValue: logic.outputs.divisionRemainderValue
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    drainMode: drainMode
    enableRecoveryServices: recoveryServices
    enableScalingTool: scalingTool
    fslogix: logic.outputs.fslogix
    fslogixContainerType: fslogixContainerType
    hostPoolName: resourceNames.outputs.hostPoolName
    hostPoolType: hostPoolType
    hybridRunbookWorkerGroupName: management.outputs.hybridRunbookWorkerGroupName
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    imageDefinitionResourceId: imageDefinitionResourceId
    location: locationVirtualMachines
    logAnalyticsWorkspaceName: resourceNames.outputs.logAnalyticsWorkspaceName
    managementVirtualMachineName: management.outputs.virtualMachineName
    maxResourcesPerTemplateDeployment: logic.outputs.maxResourcesPerTemplateDeployment
    monitoring: monitoring
    netAppFileShares: logic.outputs.fslogix ? fslogix.outputs.netAppShares : [
      'None'
    ]
    networkInterfaceNamePrefix: resourceNames.outputs.networkInterfaceNamePrefix
    organizationalUnitPath: organizationalUnitPath
    pooledHostPool: logic.outputs.pooledHostPool
    recoveryServicesVaultName: resourceNames.outputs.recoveryServicesVaultName
    resourceGroupControlPlane: resourceNames.outputs.resourceGroupControlPlane
    resourceGroupHosts: resourceNames.outputs.resourceGroupHosts
    resourceGroupManagement: resourceNames.outputs.resourceGroupManagement
    roleDefinitions: logic.outputs.roleDefinitions
    scalingBeginPeakTime: scalingBeginPeakTime
    scalingEndPeakTime: scalingEndPeakTime
    scalingLimitSecondsToForceLogOffUser: scalingLimitSecondsToForceLogOffUser
    scalingMinimumNumberOfRdsh: scalingMinimumNumberOfRdsh
    scalingSessionThresholdPerCPU: scalingSessionThresholdPerCPU
    securityPrincipalObjectIds: map(securityPrincipals, item => item.objectId)
    securityLogAnalyticsWorkspaceResourceId: securityLogAnalyticsWorkspaceResourceId
    sessionHostBatchCount: logic.outputs.sessionHostBatchCount
    sessionHostIndex: sessionHostIndex
    storageAccountPrefix: resourceNames.outputs.storageAccountNamePrefix
    storageCount: storageCount
    storageIndex: storageIndex
    storageService: logic.outputs.storageService
    storageSuffix: logic.outputs.storageSuffix
    subnet: length(deploymentLocations) == 1 ? split(network_controlPlane.outputs.subnetResourceId, '/')[10] : split(network_hosts.outputs.subnetResourceId, '/')[10]
    tags: tags
    timeDifference: logic.outputs.timeDifference
    timestamp: timestamp
    timeZone: logic.outputs.timeZone
    virtualMachineMonitoringAgent: virtualMachineMonitoringAgent
    virtualMachineNamePrefix: resourceNames.outputs.virtualMachineNamePrefix
    virtualMachinePassword: virtualMachinePassword
    virtualMachineSize: virtualMachineSize
    virtualMachineUsername: virtualMachineUsername
    virtualNetwork: length(deploymentLocations) == 1 ? split(network_controlPlane.outputs.subnetResourceId, '/')[8] : split(network_hosts.outputs.subnetResourceId, '/')[8]
    virtualNetworkResourceGroup: length(deploymentLocations) == 1 ? split(network_controlPlane.outputs.subnetResourceId, '/')[4] : split(network_hosts.outputs.subnetResourceId, '/')[4]
  }
  dependsOn: [
    fslogix
    rgs
  ]
}

module cleanUp 'modules/cleanUp/cleanUp.bicep' = {
  name: 'CleanUp_${timestamp}'
  params: {
    fslogixStorageService: fslogixStorageService
    location: locationVirtualMachines
    resourceGroupManagement: resourceNames.outputs.resourceGroupManagement
    scalingTool: scalingTool
    timestamp: timestamp
    userAssignedIdentityClientId: management.outputs.deploymentUserAssignedIdentityClientId
    virtualMachineName: management.outputs.virtualMachineName
  }
  dependsOn: [
    fslogix
    sessionHosts
  ]
}
