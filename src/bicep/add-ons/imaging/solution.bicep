targetScope = 'subscription'

@description('The file name of the ArcGIS Pro installer in Azure Blobs.')
param arcGisProInstaller string = ''

@description('The resource ID for the Azure Firewall in the HUB.')
param azureFirewallResourceId string

@description('The resource ID of the source compute gallery image.')
param computeGalleryImageResourceId string = ''

@description('The name of the container in the storage account where the installer files are located.')
param containerName string

@description('The array of customizations to apply to the image.')
param customizations array = []

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool = false

@description('Defender for Cloud enabled.')
param deployDefender bool = false

@description('The suffix to append to deployment names.')
param deploymentNameSuffix string = utcNow('yyMMddHHs')

@description('Choose whether to deploy a network watcher for deployment location.')
param deployNetworkWatcher bool = false

@description('Deploy Policy enabled.')
param deployPolicy bool = false

@description('The distribution group for email notifications.')
param distributionGroup string = ''

@secure()
@description('The password for the domain join account.')
param domainJoinPassword string = ''

@description('The user principal name for the domain join account.')
param domainJoinUserPrincipalName string = ''

@description('The domain name to join.')
param domainName string = ''

@description('The email address for the security contact.')
param emailSecurityContact string

@description('Determines whether to enable build automation.')
param enableBuildAutomation bool

@allowed([
  'dev'
  'prod'
  'test'
])
@description('The abbreviation for the environment.')
param environmentAbbreviation string = 'dev'

@description('Determines whether to exclude the image from the latest version.')
param excludeFromLatest bool = true

@description('The array of policy assignment IDs to exempt to prevent issues with the build process.')
param exemptPolicyAssignmentIds array = []

@description('The resource ID for the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('Determines whether to use the hybrid use benefit.')
param hybridUseBenefit bool

@description('The identifier for the resource names. This value should represent the workload, project, or business unit.')
param identifier string

@description('The name prefix for the image definition resource.')
param imageDefinitionNamePrefix string

@description('The major version for the name of the image version resource.')
param imageMajorVersion int

@description('The patch version for the name of the image version resource.')
param imagePatchVersion int

@description('Determines whether to install Access.')
param installAccess bool

@description('Determines whether to install ArcGIS Pro.')
param installArcGisPro bool

@description('Determines whether to install Excel.')
param installExcel bool

@description('Determines whether to install OneDrive.')
param installOneDrive bool

@description('Determines whether to install OneNote.')
param installOneNote bool

@description('Determines whether to install Outlook.')
param installOutlook bool

@description('Determines whether to install PowerPoint.')
param installPowerPoint bool

@description('Determines whether to install Project.')
param installProject bool

@description('Determines whether to install Publisher.')
param installPublisher bool

@description('Determines whether to install Skype for Business.')
param installSkypeForBusiness bool

@description('Determines whether to install Teams.')
param installTeams bool

@description('Determines whether to install Microsoft/Windows Updates.')
param installUpdates bool = false

@description('Determines whether to install the Virtual Desktop Optimization Tool.')
param installVirtualDesktopOptimizationTool bool

@description('Determines whether to install Visio.')
param installVisio bool

@description('Determines whether to install Word.')
param installWord bool

@secure()
@description('The password for the local administrator account.')
param localAdministratorPassword string

@description('The username for the local administrator account.')
param localAdministratorUsername string

@description('The location for the resources.')
param location string = deployment().location

@description('The resource ID of the log analytics workspace if using build automation and desired.')
param logAnalyticsWorkspaceResourceId string = ''

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param logStorageSkuName string = 'Standard_GRS'

@description('The marketplace image offer.')
param marketplaceImageOffer string = ''

@description('The marketplace image publisher.')
param marketplaceImagePublisher string = ''

@description('The marketplace image SKU.')
param marketplaceImageSKU string = ''

@description('The file name of the msrdcwebrtcsvc installer in Azure Blobs.')
param msrdcwebrtcsvcInstaller string = ''

@description('The network security group diagnostics logs to apply to the subnet.')
param networkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]

@description('The network security group diagnostics metrics to apply to the subnet.')
param networkSecurityGroupDiagnosticsMetrics array = []

@description('The network security group rules to apply to the subnet.')
param networkSecurityGroupRules array = []

@description('The file name of the Office installer in Azure Blobs.')
param officeInstaller string = ''

@description('The distinguished name of the organizational unit to join.')
param oUPath string = ''

@description('The policy name')
param policy string = ''

@description('The count of replicas for the image version resource.')
param replicaCount int

@allowed([
  'AzureComputeGallery'
  'AzureMarketplace'
])
@description('The type of source image.')
param sourceImageType string

@description('The resource ID of the log analytics workspace if using build automation and desired.')
param spokelogAnalyticsWorkspaceResourceId string

@description('The resource ID of the storage account where the installers and scripts are stored in Azure Blobs.')
param storageAccountResourceId string

@description('The subnet address prefix.')
param subnetAddressPrefix string = '10.0.134.0/24'

@description('The key value pairs of meta data to apply to the resources.')
param tags object = {}

@description('The file name of the Teams installer in Azure Blobs.')
param teamsInstaller string = ''

@allowed([
  'WU'
  'MU'
  'WSUS'
  'DCAT'
  'STORE'
  'OTHER'
])
@description('Determines if the updates service. (Default: \'MU\')')
param updateService string = 'MU'

@description('The file name of the vcRedist installer in Azure Blobs.')
param vcRedistInstaller string = ''

@description('The file name of the vDOT installer in Azure Blobs.')
param vDOTInstaller string = ''

@description('The size of the image virtual machine.')
param virtualMachineSize string

@description('The virtual network address prefix.')
param virtualNetworkAddressPrefix string = '10.0.134.0/24'

@description('The logs for the diagnostic setting on the virtual network.')
param virtualNetworkDiagnosticsLogs array = []

@description('The metrics for the diagnostic setting on the virtual network.')
param virtualNetworkDiagnosticsMetrics array = []

@minLength(1)
@maxLength(10)
@description('The name of the workload.')
param workloadName string = 'imaging'

@minLength(1)
@maxLength(3)
@description('The short name of the workload.')
param workloadShortName string = 'img'

@description('The WSUS Server Url if WSUS is specified. (i.e., https://wsus.corp.contoso.com:8531)')
param wsusServer string = ''

var automationAccountPrivateDnsZoneResourceId = resourceId(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4], 'Microsoft.Network/privateDnsZones','privatelink.azure-automation.${privateDnsZoneSuffixes_AzureAutomation[environment().name] ?? cloudSuffix}')
var calculatedTags = union(tags, defaultTags)
var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.azure.', ''), '/', '')
var defaultTags = {
  DeploymentType: 'MissionLandingZoneARM'
}
var keyVaultPrivateDnsZoneResourceId = resourceId(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4], 'Microsoft.Network/privateDnsZones', replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore'))
var imageDefinitionName = empty(computeGalleryImageResourceId) ? '${imageDefinitionNamePrefix}-${marketplaceImageSKU}' : '${imageDefinitionNamePrefix}-${split(computeGalleryImageResourceId, '/')[10]}'
var privateDnsZoneSuffixes_AzureAutomation = {
  AzureCloud: 'net'
  AzureUSGovernment: 'us'
  USNat: null
  USSec: null
}
var subscriptionId = subscription().subscriptionId
var locations = (loadJsonContent('../../data/locations.json'))[environment().name]

module tier3 '../tier3/solution.bicep' = {
  name: 'tier3-${deploymentNameSuffix}'
  params: {
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcher: deployNetworkWatcher
    deployPolicy:  deployPolicy
    emailSecurityContact: emailSecurityContact
    environmentAbbreviation: environmentAbbreviation
    firewallResourceId: azureFirewallResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    location: location
    logAnalyticsWorkspaceResourceId: spokelogAnalyticsWorkspaceResourceId
    logStorageSkuName: logStorageSkuName
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs 
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupRules: networkSecurityGroupRules
    policy: policy
    resourcePrefix: identifier
    tags: calculatedTags
    subnetAddressPrefix: subnetAddressPrefix
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    workloadName: workloadName
    workloadShortName: workloadShortName
  }
}

module baseline 'modules/baseline.bicep' = {
  name: 'baseline-${deploymentNameSuffix}'
  params: {
    computeGalleryName: tier3.outputs.network.computeGalleryName
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: tier3.outputs.diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    exemptPolicyAssignmentIds: exemptPolicyAssignmentIds
    location: location
    resourceGroupName: tier3.outputs.network.resourceGroupName
    storageAccountResourceId: storageAccountResourceId
    subscriptionId: subscriptionId
    tags: calculatedTags
    userAssignedIdentityName: tier3.outputs.network.userAssignedIdentityName
  }
}

module buildAutomation 'modules/buildAutomation.bicep' = if (enableBuildAutomation) {
  name: 'build-automation-${deploymentNameSuffix}'
  params: {
    actionGroupName: tier3.outputs.network.actionGroupName
    arcGisProInstaller: arcGisProInstaller
    automationAccountName: tier3.outputs.network.automationAccountName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryResourceId: baseline.outputs.computeGalleryResourceId
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: tier3.outputs.diskEncryptionSetResourceId
    distributionGroup: distributionGroup
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imagePatchVersion: imagePatchVersion
    imageVirtualMachineName: replace(tier3.outputs.network.virtualMachineName, tier3.outputs.tokens.service, 'b')
    installAccess: installAccess
    installArcGisPro: installArcGisPro
    installExcel: installExcel
    installOneDrive: installOneDrive
    installOneNote: installOneNote
    installOutlook: installOutlook
    installPowerPoint: installPowerPoint
    installProject: installProject
    installPublisher: installPublisher
    installSkypeForBusiness: installSkypeForBusiness
    installTeams: installTeams
    installUpdates: installUpdates
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    keyVaultName: tier3.outputs.network.keyVaultName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: replace(tier3.outputs.network.virtualMachineName, tier3.outputs.tokens.service, 'm')
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: tier3.outputs.network.resourceGroupName
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: tier3.outputs.subnetResourceId
    subscriptionId: subscriptionId
    tags: calculatedTags
    teamsInstaller: teamsInstaller
    timeZone: locations[location].timeZone
    updateService: updateService
    userAssignedIdentityClientId: baseline.outputs.userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: baseline.outputs.userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: baseline.outputs.userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineSize: virtualMachineSize
    wsusServer: wsusServer
  }
  dependsOn: [
    tier3
  ]
}

module imageBuild 'modules/imageBuild.bicep' = {
  name: 'image-build-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryName: tier3.outputs.network.computeGalleryName
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: tier3.outputs.diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imagePatchVersion: imagePatchVersion
    imageVirtualMachineName: replace(tier3.outputs.network.windowsVmName, tier3.outputs.tokens.service, 'b')
    installAccess: installAccess
    installArcGisPro: installArcGisPro
    installExcel: installExcel
    installOneDrive: installOneDrive
    installOneNote: installOneNote
    installOutlook: installOutlook
    installPowerPoint: installPowerPoint
    installProject: installProject
    installPublisher: installPublisher
    installSkypeForBusiness: installSkypeForBusiness
    installTeams: installTeams
    installUpdates: installUpdates
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    keyVaultName: tier3.outputs.network.keyVaultName
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    managementVirtualMachineName: replace(tier3.outputs.network.windowsVmName, tier3.outputs.tokens.service, 'm')
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    replicaCount: replicaCount
    resourceGroupName: tier3.outputs.network.resourceGroupName
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: calculatedTags
    teamsInstaller: teamsInstaller
    updateService: updateService
    userAssignedIdentityClientId: baseline.outputs.userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: baseline.outputs.userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: baseline.outputs.userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineSize: virtualMachineSize
    wsusServer: wsusServer
  }
  dependsOn: [
    buildAutomation
  ]
}

output imageDefinitionResourceId string = imageBuild.outputs.imageDefinitionResourceId
