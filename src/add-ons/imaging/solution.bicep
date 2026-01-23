targetScope = 'subscription'

@description('The file name of the ArcGIS Pro installer in Azure Blobs.')
param arcGisProInstaller string = ''

@description('The resource ID for the Azure Firewall in the HUB.')
param azureFirewallResourceId string

@description('The resource ID of the source compute gallery image.')
param computeGalleryImageResourceId string = ''

@description('The name of the container in the storage account where the installer files are located.')
param containerName string

@description('The custom firewall rule collection groups that override the default firewall rule collection groups.')
param customFirewallRuleCollectionGroups array = []

@description('The array of customizations to apply to the image. Limit of 25 runCommands per virtual machine applies. Depending on other features used, the limit may be lower.')
param customizations array = []

// Example customizations array
/* 
[
  {
    name: 'InstallBundle'
    blobName: 'Install-BundleSoftware.ps1'
    arguments: '-BundleManifestBlob bundlemanifest.json'
    enabled: false
  }
] 
*/

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool = false

@description('Defender for Cloud enabled.')
param deployDefender bool = false

@description('The suffix to append to deployment names.')
param deploymentNameSuffix string = utcNow('yyMMddHHs')

@description('When set to true, deploys Network Watcher Traffic Analytics. It defaults to "false".')
param deployNetworkWatcherTrafficAnalytics bool = false

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
param emailSecurityContact string = ''

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

@description('The resource ID for the storage account in the HUB.')
param hubStorageAccountResourceId string

@description('The resource ID for the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('Determines whether to use the hybrid use benefit.')
param hybridUseBenefit bool

@maxLength(3)
@description('The identifier for the resource names. This value should represent the workload, project, or business unit.')
param identifier string

@description('The name prefix for the image definition resource.')
param imageDefinitionNamePrefix string

@description('The major version for the name of the image version resource.')
param imageMajorVersion int

@description('The minor version for the name of the image version resource.')
param imageMinorVersion int

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

@description('An array of Key Vault Diagnostic Logs categories to collect. See "https://learn.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault" for valid values.')
param keyVaultDiagnosticLogs array = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]

@description('The Key Vault Diagnostic Metrics to collect. See the following URL for valid settings: "https://learn.microsoft.com/azure/key-vault/general/logging?tabs=Vault".')
param keyVaultDiagnosticMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The location for the resources.')
param location string = deployment().location

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See the following URL for valid settings: https://learn.microsoft.com/rest/api/storagerp/srp_sku_types.')
param logStorageSkuName string = 'Standard_GRS'

@description('The marketplace image offer.')
param marketplaceImageOffer string = ''

@description('The marketplace image publisher.')
param marketplaceImagePublisher string = ''

@description('The marketplace image SKU.')
param marketplaceImageSKU string = ''

@description('The file name of the msrdcwebrtcsvc installer in Azure Blobs.')
param msrdcwebrtcsvcInstaller string = ''

@description('An array of metrics to enable on the diagnostic setting for network interfaces.')
param networkInterfaceDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

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

@description('The network security group rules to apply to the subnet.')
param networkSecurityGroupRules array = []

@description('The number of days to retain Network Watcher Flow Logs. It defaults to "30".')  
param networkWatcherFlowLogsRetentionDays int = 30

@allowed([
  'NetworkSecurityGroup'
  'VirtualNetwork'
])
@description('When set to "true", enables Virtual Network Flow Logs. It defaults to "true" as its required by MCSB.')
param networkWatcherFlowLogsType string = 'VirtualNetwork'

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
param spokeLogAnalyticsWorkspaceResourceId string

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

@secure()
@description('The password for the local administrator account on the virtual machines.')
param virtualMachineAdminPassword string

@secure()
@description('The username for the local administrator account on the virtual machines.')
param virtualMachineAdminUsername string

@description('The size of the image virtual machine.')
param virtualMachineSize string

@description('The virtual network address prefix.')
param virtualNetworkAddressPrefix string = '10.0.134.0/24'

@description('The logs for the diagnostic setting on the virtual network.')
param virtualNetworkDiagnosticsLogs array = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]

@description('The metrics for the diagnostic setting on the virtual network.')
param virtualNetworkDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('The WSUS Server Url if WSUS is specified. (i.e., https://wsus.corp.contoso.com:8531)')
param wsusServer string = ''

var keyVaultPrivateDnsZoneResourceId = resourceId(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4], 'Microsoft.Network/privateDnsZones', replace('privatelink${environment().suffixes.keyvaultDns}', 'vault', 'vaultcore'))
var imageDefinitionName = empty(computeGalleryImageResourceId) ? '${imageDefinitionNamePrefix}-${marketplaceImageSKU}' : '${imageDefinitionNamePrefix}-${split(computeGalleryImageResourceId, '/')[10]}'
var workloadName = 'imaging'
var workloadShortName = 'img'

module tier3 '../tier3/solution.bicep' = {
  name: 'deploy-tier3-${deploymentNameSuffix}'
  params: {
    customFirewallRuleCollectionGroups: empty(customFirewallRuleCollectionGroups)
      ? [
          {
            name: 'IMG-CollapsedCollectionGroup-${toUpper(identifier)}-${toUpper(environmentAbbreviation)}-${toUpper(location)}'
            properties: {
              priority: 200
              ruleCollections: [
                {
                  name: 'NetworkRules'
                  priority: 100
                  ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
                  action: {
                    type: 'Allow'
                  }
                  rules: concat(
                    [
                      {
                        name: 'KMS-Endpoint'
                        ruleType: 'NetworkRule'
                        ipProtocols: [
                          'Tcp'
                        ]
                        sourceAddresses: [
                          virtualNetworkAddressPrefix
                        ]
                        destinationAddresses: []
                        destinationFqdns: [
                          'azkms.${environment().suffixes.storage}'
                          'kms.${environment().suffixes.storage}'
                        ]
                        destinationPorts: [
                          '1688'
                        ]
                        sourceIpGroups: []
                        destinationIpGroups: []
                      }
                    ],
                    [
                      {
                        name: 'AzureCloudforLogin'
                        ruleType: 'NetworkRule'
                        ipProtocols: [
                          'Tcp'
                        ]
                        sourceAddresses: [
                          virtualNetworkAddressPrefix
                        ]
                        destinationAddresses: ['AzureActiveDirectory']
                        destinationFqdns: []
                        destinationPorts: [
                          '443'
                        ]
                        sourceIpGroups: []
                        destinationIpGroups: []
                      }
                    ]
                  )
                }
                {
                  name: 'ApplicationRules'
                  priority: 200
                  ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
                  action: {
                    type: 'Allow'
                  }
                  rules: concat(
                    [
                      {
                        name: 'IMG-RequiredDeploymentEndpoints'
                        ruleType: 'ApplicationRule'
                        protocols: [
                          {
                            protocolType: 'Https'
                            port: 443
                          }
                        ]
                        fqdnTags: []
                        webCategories: []
                        targetFqdns: [
                          split(environment().resourceManager, '/')[2]
                        ]
                        targetUrls: []
                        terminateTLS: false
                        sourceAddresses: [
                          virtualNetworkAddressPrefix
                        ]
                        destinationAddresses: []
                        sourceIpGroups: []
                      }
                    ],
                    installUpdates
                      ? [
                          {
                            name: 'WindowsUpdateEndpoints'
                            ruleType: 'ApplicationRule'
                            protocols: [
                              {
                                protocolType: 'Https'
                                port: 443
                              }
                            ]
                            fqdnTags: [
                              'WindowsUpdate'
                            ]
                            webCategories: []
                            targetFqdns: []
                            targetUrls: []
                            terminateTLS: false
                            sourceAddresses: [
                              virtualNetworkAddressPrefix
                            ]
                            destinationAddresses: []
                            sourceIpGroups: []
                          }
                        ]
                      : []
                  )
                }
              ]
            }
          }
        ]
      : customFirewallRuleCollectionGroups
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    deployPolicy:  deployPolicy
    emailSecurityContact: emailSecurityContact
    environmentAbbreviation: environmentAbbreviation
    firewallResourceId: azureFirewallResourceId
    hubStorageAccountResourceId: hubStorageAccountResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    identifier: identifier
    keyVaultDiagnosticLogs: keyVaultDiagnosticLogs
    keyVaultDiagnosticMetrics: keyVaultDiagnosticMetrics
    location: location
    logAnalyticsWorkspaceResourceId: spokeLogAnalyticsWorkspaceResourceId
    logStorageSkuName: logStorageSkuName
    networkInterfaceDiagnosticsMetrics: networkInterfaceDiagnosticsMetrics
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs 
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    policy: policy
    subnetAddressPrefix: subnetAddressPrefix
    subnetName: 'Imaging'
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    windowsAdministratorsGroupMembership: virtualMachineAdminUsername
    workloadName: workloadName
    workloadShortName: workloadShortName
  }
}

module baseline 'modules/baseline.bicep' = {
  name: 'deploy-imaging-baseline-${deploymentNameSuffix}'
  params: {
    delimiter: tier3.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableBuildAutomation: enableBuildAutomation
    environmentAbbreviation: environmentAbbreviation
    exemptPolicyAssignmentIds: exemptPolicyAssignmentIds
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    mlzTags: tier3.outputs.mlzTags
    resourceAbbreviations: tier3.outputs.resourceAbbreviations
    storageAccountResourceId: storageAccountResourceId
    tags: tags
    tier: tier3.outputs.tier
  }
}

module buildAutomation 'modules/build-automation.bicep' = if (enableBuildAutomation) {
  name: 'deploy-build-automation-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    automationAccountPrivateDnsZoneResourceId: resourceId(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4], 'Microsoft.Network/privateDnsZones', filter(tier3.outputs.privateDnsZones, name => startsWith(name, 'privatelink.azure-automation'))[0])
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryResourceId: baseline.outputs.computeGalleryResourceId
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: baseline.outputs.diskEncryptionSetResourceId
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
    imagePatchVersion: imagePatchVersion
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
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    location: location
    locationProperties: tier3.outputs.locationProperties
    logAnalyticsWorkspaceResourceId: spokeLogAnalyticsWorkspaceResourceId
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    mlzTags: tier3.outputs.mlzTags
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: baseline.outputs.resourceGroupName
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    tags: tags
    teamsInstaller: teamsInstaller
    tier: tier3.outputs.tier
    updateService: updateService
    userAssignedIdentityClientId: baseline.outputs.userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: baseline.outputs.userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: baseline.outputs.userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
    wsusServer: wsusServer
  }
}

module imageBuild 'modules/image-build.bicep' = {
  name: 'build-image-${deploymentNameSuffix}'
  params: {
    arcGisProInstaller: arcGisProInstaller
    computeGalleryImageResourceId: computeGalleryImageResourceId
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: baseline.outputs.diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imagePatchVersion: imagePatchVersion
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
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    mlzTags: tier3.outputs.mlzTags
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    replicaCount: replicaCount
    resourceGroupName: baseline.outputs.resourceGroupName
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
    tags: tags
    teamsInstaller: teamsInstaller
    tier: tier3.outputs.tier
    updateService: updateService
    userAssignedIdentityClientId: baseline.outputs.userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: baseline.outputs.userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: baseline.outputs.userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
    wsusServer: wsusServer
  }
  dependsOn: [
    buildAutomation
  ]
}

output imageDefinitionResourceId string = imageBuild.outputs.imageDefinitionResourceId
