targetScope = 'subscription'

@description('The file name of the ArcGIS Pro installer in Azure Blobs.')
param arcGisProInstaller string = ''

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool = false

@description('The name for the action group resource.')
param actionGroupName string = ''

@description('The name for the automation account resource.')
param automationAccountName string

@description('The private DNS zone resource ID for the automation account resource.')
param automationAccountPrivateDnsZoneResourceId string

@description('The resource ID for the Azure Firewall in the HUB.')
param azureFirewallResourceId string

@description('The resource ID of the compute gallery image.')
param computeGalleryImageResourceId string = ''

@description('The name of the compute gallery resource.')
param computeGalleryName string

@description('The name of the container in the storage account where the installer files are located.')
param containerName string

@description('The array of customizations to apply to the image.')
param customizations array = []

@description('The resource ID of the disk encryption set to use for the management virtual machine.')
param diskEncryptionSetResourceId string = ''

@description('The distribution group for email notifications.')
param distributionGroup string = ''


@description('Defender for Cloud enabled.')
param deployDefender bool = false

@description('Deploy Policy enabled.')
param deployPolicy bool = false


@description('The suffix to append to deployment names.')
param deploymentNameSuffix string = utcNow('yyMMddHHs')

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

@description('Determines whether to exclude the image from the latest version.')
param excludeFromLatest bool = true

@description('Determines whether to use an existing resource group.')
param existingResourceGroup bool = false

@description('The array of policy assignment IDs to exempt to prevent issues with the build process.')
param exemptPolicyAssignmentIds array = []

@description('The hub resource group name.')
param hubResourceGroupName string

@description('The name of hub subscription.')
param hubSubscriptionId string

@description('The hub virtual network name.')
param hubVirtualNetworkName string

@description('Determines whether to use the hybrid use benefit.')
param hybridUseBenefit bool

@description('The name of the hybrid worker (virtual machine) if using build automation.')
param hybridWorkerName string = ''

@description('The name prefix for the image definition resource.')
param imageDefinitionNamePrefix string

@description('The major version for the name of the image version resource.')
param imageMajorVersion int

@description('The minor version for the name of the image version resource.')
param imageMinorVersion int

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

@description('The name of the key vault resource.')
param keyVaultName string

@description('The private DNS zone resource ID for the key vault resource.')
param keyVaultPrivateDnsZoneResourceId string

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

@description('The resource ID of the log analytics workspace if using build automation and desired.')
param spokelogAnalyticsWorkspaceResourceId string

@description('The marketplace image offer.')
param marketplaceImageOffer string = ''

@description('The marketplace image publisher.')
param marketplaceImagePublisher string = ''

@description('The marketplace image SKU.')
param marketplaceImageSKU string = ''

@description('The file name of the msrdcwebrtcsvc installer in Azure Blobs.')
param msrdcwebrtcsvcInstaller string = ''

@description('The network security group diagnostics logs to apply to the subnet.')
param networkSecurityGroupDiagnosticsLogs array = []

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

@description('The name of the resource group.')
param resourceGroupName string

@description('The prefix for the resource names.')
param resourcePrefix string


@allowed([
  'AzureComputeGallery'
  'AzureMarketplace'
])
@description('The type of source image.')
param sourceImageType string

@description('The resource ID of the storage account where the installers and scripts are stored in Azure Blobs.')
param storageAccountResourceId string

@description('The subnet address prefix.')
param subnetAddressPrefix string

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

@description('The name of the user assigned identity resource.')
param userAssignedIdentityName string

@description('The file name of the vcRedist installer in Azure Blobs.')
param vcRedistInstaller string = ''

@description('The file name of the vDOT installer in Azure Blobs.')
param vDOTInstaller string = ''

@description('The virtual network address prefix.')
param virtualNetworkAddressPrefix string

@description('The logs for the diagnostic setting on the virtual network.')
param virtualNetworkDiagnosticsLogs array = []

@description('The metrics for the diagnostic setting on the virtual network.')
param virtualNetworkDiagnosticsMetrics array = []

@description('The size of the image virtual machine.')
param virtualMachineSize string

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

var imageDefinitionName = empty(computeGalleryImageResourceId) ? '${imageDefinitionNamePrefix}-${marketplaceImageSKU}' : '${imageDefinitionNamePrefix}-${split(computeGalleryImageResourceId, '/')[10]}'
var imageVirtualMachineName = take('vmimg-${uniqueString(deploymentNameSuffix)}', 15)
var managementVirtualMachineName = empty(hybridWorkerName) ? take('vmmgt-${uniqueString(deploymentNameSuffix)}', 15) : hybridWorkerName
var subscriptionId = subscription().subscriptionId
var locations = (loadJsonContent('../../data/locations.json'))[environment().name]

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  name: hubVirtualNetworkName
}

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = if (!existingResourceGroup) {
  name: resourceGroupName
  location: location
  tags: tags
}

module tier3 '../tier3/solution.bicep' = {
  name: 'tier3-${deploymentNameSuffix}'
  params: {
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deploymentNameSuffix: deploymentNameSuffix
    deployPolicy:  deployPolicy
    emailSecurityContact: emailSecurityContact
    firewallResourceId: azureFirewallResourceId
    hubVirtualNetworkResourceId: hubVirtualNetwork.id
    location: location
    logAnalyticsWorkspaceResourceId: spokelogAnalyticsWorkspaceResourceId
    logStorageSkuName: logStorageSkuName
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs 
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics
    networkSecurityGroupRules: networkSecurityGroupRules
    policy: policy
    resourcePrefix: resourcePrefix
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
    computeGalleryName: computeGalleryName
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    exemptPolicyAssignmentIds: exemptPolicyAssignmentIds
    location: location
    resourceGroupName: existingResourceGroup ? resourceGroupName : rg.name
    storageAccountResourceId: storageAccountResourceId
    subscriptionId: subscriptionId
    tags: tags
    userAssignedIdentityName: userAssignedIdentityName
  }
  dependsOn: [
    tier3
  ]
}

module buildAutomation 'modules/buildAutomation.bicep' = if (enableBuildAutomation) {
  name: 'build-automation-${deploymentNameSuffix}'
  params: {
    actionGroupName: actionGroupName
    arcGisProInstaller: arcGisProInstaller
    automationAccountName: automationAccountName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryResourceId: baseline.outputs.computeGalleryResourceId
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    distributionGroup: distributionGroup
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
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
    keyVaultName: keyVaultName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: managementVirtualMachineName
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: existingResourceGroup ? resourceGroupName : rg.name
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: tier3.outputs.subnetResourceId
    subscriptionId: subscriptionId
    tags: tags
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
  scope: resourceGroup(subscriptionId, (existingResourceGroup ? rg.name : resourceGroupName))
  params: {
    arcGisProInstaller: arcGisProInstaller
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryName: computeGalleryName
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
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
    keyVaultName: keyVaultName
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    replicaCount: replicaCount
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: tier3.outputs.subnetResourceId
    tags: tags
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
    tier3
  ]
}
