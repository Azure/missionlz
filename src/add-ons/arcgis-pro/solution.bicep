targetScope = 'subscription'

@secure()
@description('The Azure Active Directory Graph API access token with sufficient permissions to deploy Entra Cloud Sync. Refer to the documentation to get this value. It is only supported in AzureCloud / Commercial.')
param aadGraphAccessToken string = ''

@description('The root domain name for the new forest in Active Directory Domain Services. Required when deployActiveDirectoryDomainServices is true.')
param addsDomainName string = ''

@secure()
@description('The password for the safe mode administrator account. Required when deployActiveDirectoryDomainServices is true.')
param addsSafeModeAdminPassword string = ''

@description('The password for the local administrator accounts on the Active Directory Domain Services (ADDS) domain controllers. Required when deployActiveDirectoryDomainServices is true.')
@secure()
param addsVmAdminPassword string = ''

@description('The username for the local administrator accounts on the Active Directory Domain Services (ADDS) domain controllers. Required when deployActiveDirectoryDomainServices is true.')
param addsVmAdminUsername string = ''

@allowed([
  '2019-datacenter-core-g2' // Windows Server 2019 Datacenter Core Gen2
  '2019-datacenter-gensecond' // Windows Server 2019 Datacenter Gen2
  '2022-datacenter-core-g2' // Windows Server 2022 Datacenter Core Gen2
  '2022-datacenter-g2' // Windows Server 2022 Datacenter Gen2
])
@description('The Windows image SKU in the Azure marketplace for the Active Directory Domain Services (ADDS) domain controllers.')
param addsVmImageSku string = '2019-datacenter-gensecond'

@description('The virtual machine size for the Active Directory Domain Services (ADDS) domain controllers.')
param addsVmSize string = 'Standard_D2s_v3'

// @secure()
// @description('The password for the ArcGIS service account.')
// param arcgisServiceAccountPassword string

// @description('The username for the ArcGIS service account.')
// param arcgisServiceAccountUsername string

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool

@description('Choose whether to deploy Defender for Cloud.')
param deployDefender bool

@description('The suffix used for naming deployments uniquely. It defaults to a timestamp with the utcNow function.')
param deploymentNameSuffix string = utcNow()

@description('Choose whether to deploy a policy assignment.')
param deployPolicy bool

@description('Determines whether to use the hybrid use benefit for the Windows virtual machines.')
param hybridUseBenefit bool

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

// @description('The base 64 encoded string containing the license file for the ESRI portal.')
// param portalLicenseFile string

// @allowed([
//   'creatorUT'
//   'editorUT'
//   'fieldWorkerUT'
//   'GISProfessionalAdvUT'
//   'GISProfessionalBasicUT'
//   'GISProfessionalStdUT'
//   'IndoorsUserUT'
//   'insightsAnalystUT'
//   'viewerUT'
// ])
// @description('The license user type ID for the ESRI portal.')
// param portalLicenseUserTypeId string

// @secure()
// @description('The password for the ESRI Primary Site Administrator Account.')
// param primarySiteAdministratorAccountPassword string

// @description('The username for the ESRI Primary Site Administrator Account.')
// param primarySiteAdministratorAccountUserName string

@description('The array of Security Principals with their object IDs and display names to assign to the AVD Application Group and FSLogix Storage.')
param securityPrincipals array

// @description('The base 64 encoded string containing the license file for ESRI Enterprise server.')
// param serverLicenseFile string

// @description('The resource ID of the Azure Storage Account used for storing the deployment artifacts.')
// param storageAccountResourceId string

@description('A string dictionary of tags to add to deployed resources. See the following URL for valid settings: https://learn.microsoft.com/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates.')
param tags object = {}

@secure()
@description('The password for the local administrator account on the virtual machines.')
param virtualMachineAdminPassword string

@description('The username for the local administrator account on the virtual machines.')
param virtualMachineAdminUsername string

@allowed([
  'Standard_NV4as_v4'
  'Standard_NV8as_v4'
  'Standard_NV16as_v4'
  'Standard_NV32as_v4'
])
@description('The virtual machine SKU for the AVD session hosts.')
param virtualMachineSize string = 'Standard_NV4as_v4'

module missionLandingZone '../../mlz.bicep' = {
  name: 'deploy-mission-landing-zone-${deploymentNameSuffix}'
  params: {
    addsDomainName: addsDomainName
    addsSafeModeAdminPassword: addsSafeModeAdminPassword
    addsVmAdminPassword: addsVmAdminPassword
    addsVmAdminUsername: addsVmAdminUsername
    addsVmImageSku: addsVmImageSku
    addsVmSize: addsVmSize
    deployActiveDirectoryDomainServices: true
    deployBastion: true
    deployIdentity: true
    deployNetworkWatcherTrafficAnalytics: true
    environmentAbbreviation: 'dev'
    firewallSkuTier: 'Standard'
    hybridUseBenefit: hybridUseBenefit
    identifier: 'poc'
    location: location
    tags: tags
  }
}

module entraCloudSync 'entra-cloud-sync.bicep' = if (deployEntraCloudSync) {
  name: 'deploy-entra-cloud-sync-${deploymentNameSuffix}'
  scope: resourceGroup(tier.subscriptionId, resourceGroupName)
  params: {
    accessToken: aadGraphAccessToken
    adminPassword: adminPassword
    adminUsername: adminUsername
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    domainName: domainName
    location: location
    mlzTags: mlzTags
    subnetResourceId: tier.subnetResourceId
    tags: tags
    tier: tier
    tokens: tokens
    virtualMachineNames: [
      domainControllers[0].outputs.virtualMachineName
      domainControllers[1].outputs.virtualMachineName
    ]
  }
}

module azureVirtualDesktop '../azure-virtual-desktop/solution.bicep' = {
  name: 'deploy-azure-virtual-desktop-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: 'MicrosoftEntraId'
    availability: 'None'
    avdObjectId: avdObjectId
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deployPolicy: deployPolicy
    enableAcceleratedNetworking: true
    environmentAbbreviation: 'dev'
    fslogixStorageService: 'None'
    hubAzureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    hubStorageAccountResourceId: missionLandingZone.outputs.hubStorageAccountResourceId
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    identifier: 'poc'
    locationVirtualMachines: location
    operationsLogAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    privateLinkScopeResourceId: missionLandingZone.outputs.privateLinkScopeResourceId
    securityPrincipals: securityPrincipals
    sharedServicesSubnetResourceId: missionLandingZone.outputs.sharedServicesSubnetResourceId
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
    virtualMachineVirtualCpuCount: int(replace(replace(virtualMachineSize, 'Standard_NV', ''), 'as_v4', ''))
  }
}

module azureNetAppFiles '../azure-netapp-files/solution.bicep' = {
  name: 'deploy-azure-netapp-files-${deploymentNameSuffix}'
  params: {
    azureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deploymentNameSuffix: deploymentNameSuffix
    deployPolicy: deployPolicy
    domainJoinPassword: virtualMachineAdminPassword
    domainJoinUserPrincipalName: virtualMachineAdminUsername
    domainName: addsDomainName
    environmentAbbreviation: 'dev'
    fileShareName: 'arcgispro'
    hubStorageAccountResourceId: missionLandingZone.outputs.hubStorageAccountResourceId
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    identifier: 'poc'
    location: location
    logAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    sku: 'Standard'
    tags: tags
  }
}

// Commented out the ArcGIS Enterprise deployment until its ready
/* module arcGisEnterprise '../esri-enterprise/solution.bicep' = {
  name: 'deploy-esri-enterprise-${deploymentNameSuffix}'
  params: {
    adminPassword: virtualMachineAdminPassword
    adminUsername: virtualMachineAdminUsername
    arcgisServiceAccountIsDomainAccount: true
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUsername: arcgisServiceAccountUsername
    architecture: 'singletier'
    artifactsContainerName: containerName
    artifactsStorageAccountName: split(storageAccountResourceId, '/')[8]
    artifactsStorageAccountResourceGroupName: split(storageAccountResourceId, '/')[4]
    artifactsStorageAccountSubscriptionId: split(storageAccountResourceId, '/')[2]
    azureFirewallName: split(missionLandingZone.outputs.azureFirewallResourceId, '/')[8]
    certificateFileName: certificateFileName
    certificatePassword: certificatePassword
    deployDefender: false
    diskEncryptionSetResourceId: missionLandingZone.outputs.diskEncryptionSetResourceId
    enableGraphDataStore: false
    enableMonitoring: true
    enableObjectDataStore: false
    enableSpatiotemporalBigDataStore: true
    enableTileCacheDataStore: true
    externalDnsHostname: 'esri.${domainName}'
    hubResourceGroupName: split(missionLandingZone.outputs.hubVirtualNetworkResourceId, '/')[4]
    hubSubscriptionId: subscription().subscriptionId
    hubVirtualNetworkName: split(missionLandingZone.outputs.hubVirtualNetworkResourceId, '/')[8]
    joinEntraDomain: false
    joinWindowsDomain: true
    location: location
    portalLicenseFile: portalLicenseFile
    portalLicenseUserTypeId: portalLicenseUserTypeId
    primarySiteAdministratorAccountPassword: primarySiteAdministratorAccountPassword
    primarySiteAdministratorAccountUserName: primarySiteAdministratorAccountUserName
    resourcePrefix: identifier
    selfSignedCertificatePassword: certificatePassword
    serverLicenseFile: serverLicenseFile
    spokelogAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    useAzureFiles: false
    useCloudStorage: false
    windowsDomainAdministratorPassword: virtualMachineAdminPassword
    windowsDomainAdministratorUserName: virtualMachineAdminUsername
    windowsDomainName: domainName
  }
} */
