targetScope = 'subscription'

@secure()
@description('The password for the ArcGIS service account.')
param arcgisServiceAccountPassword string

@description('The username for the ArcGIS service account.')
param arcgisServiceAccountUserName string

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

@description('The file name for the certificate that will secure the ESRI portal. The file must be hosted in an Azure Blobs container with the other deployment artifacts.')
param certificateFileName string

@secure()
@description('The password for the certificate that will secure the ESRI portal.')
param certificatePassword string

@description('The name of the container in Azure Blobs for the deployment artifacts.')
param containerName string

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool

@description('Choose whether to deploy Defender for Cloud.')
param deployDefender bool

@description('The suffix used for naming deployments uniquely. It defaults to a timestamp with the utcNow function.')
param deploymentNameSuffix string = utcNow()

@description('Choose whether to deploy Network Watcher for the deployment location.')
param deployNetworkWatcher bool

@description('Choose whether to deploy a policy assignment.')
param deployPolicy bool

@secure()
@description('The password for the domain join account that will be created in Entra Domain Services.')
param domainJoinPassword string

@description('The username for the domain join account that will be created in Entra Domain Services.')
param domainJoinUsername string = 'domainjoin'

@description('The name of the domain to use for Entra Domain Services.')
param domainName string

@description('The email address or distribution list to receive security alerts.')
param emailSecurityContact string = ''

@description('Determines whether to use the hybrid use benefit for the Windows virtual machines.')
param hybridUseBenefit bool

@minLength(1)
@maxLength(3)
@description('The unique identifier between the business unit or project this solution will support.')
param identifier string

@secure()
@description('The password for the local administrator account on the virtual machines.')
param localAdministratorPassword string

@description('The username for the local administrator account on the virtual machines.')
param localAdministratorUsername string

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@description('The resource ID of the Log Analytics Workspace to use for log storage.')
param operationsLogAnalyticsWorkspaceResourceId string

@description('The base 64 encoded string containing the license file for the ESRI portal.')
param portalLicenseFile string

@allowed([
  'creatorUT'
  'editorUT'
  'fieldWorkerUT'
  'GISProfessionalAdvUT'
  'GISProfessionalBasicUT'
  'GISProfessionalStdUT'
  'IndoorsUserUT'
  'insightsAnalystUT'
  'viewerUT'
])
@description('The license user type ID for the ESRI portal.')
param portalLicenseUserTypeId string

@secure()
@description('The password for the ESRI Primary Site Administrator Account.')
param primarySiteAdministratorAccountPassword string

@description('The username for the ESRI Primary Site Administrator Account.')
param primarySiteAdministratorAccountUserName string

@minLength(3)
@maxLength(6)
@description('A prefix, 3-6 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string

@description('The array of Security Principals with their object IDs and display names to assign to the AVD Application Group and FSLogix Storage.')
param securityPrincipals array

@description('The base 64 encoded string containing the license file for ESRI Enterprise server.')
param serverLicenseFile string

@description('The resource ID of the Azure Storage Account used for storing the deployment artifacts.')
param storageAccountResourceId string

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
    environmentAbbreviation: 'dev'
    deployIdentity: true
    firewallSkuTier: 'Standard'
    hybridUseBenefit: hybridUseBenefit
    location: location
    resourcePrefix: resourcePrefix
  }
}

module azureVirtualDesktop '../azure-virtual-desktop/solution.bicep' = {
  name: 'deploy-azure-virtual-desktop-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: 'MicrosoftEntraDomainServices'
    availability: 'None'
    avdObjectId: avdObjectId
    azureNetAppFilesSubnetAddressPrefix: '10.0.140.128/25'
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deployNetworkWatcher: deployNetworkWatcher
    deployPolicy: deployPolicy
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: '${domainJoinUsername}@${domainName}'
    domainName: domainName
    emailSecurityContact: emailSecurityContact
    environmentAbbreviation: 'dev'
    fslogixStorageService: 'AzureNetAppFiles Premium'
    hostPoolPublicNetworkAccess: 'Enabled'
    hubAzureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    identifier: identifier
    locationVirtualMachines: location
    operationsLogAnalyticsWorkspaceResourceId: operationsLogAnalyticsWorkspaceResourceId
    organizationalUnitPath: 'OU=AADDC Computers,DC=${replace(domainName, '.', ',DC=')}'
    securityPrincipals: securityPrincipals
    sharedServicesSubnetResourceId: missionLandingZone.outputs.sharedServicesSubnetResourceId
    subnetAddressPrefixes: ['10.0.140.0/25']
    virtualMachinePassword: localAdministratorPassword
    virtualMachineSize: virtualMachineSize
    virtualMachineUsername: localAdministratorUsername
    virtualMachineVirtualCpuCount: int(replace(replace(virtualMachineSize, 'Standard_NV', ''), 'as_v4', ''))
    virtualNetworkAddressPrefixes: ['10.0.140.0/24']
    workspacePublicNetworkAccess: 'Enabled'
  }
}

module esriEnterprise '../esri-enterprise/solution.bicep' = {
  name: 'deploy-esri-enterprise-${deploymentNameSuffix}'
  params: {
    adminPassword: localAdministratorPassword
    adminUsername: localAdministratorUsername
    arcgisServiceAccountIsDomainAccount: true
    arcgisServiceAccountPassword: arcgisServiceAccountPassword
    arcgisServiceAccountUserName: arcgisServiceAccountUserName
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
    resourcePrefix: resourcePrefix
    selfSignedCertificatePassword: certificatePassword
    serverLicenseFile: serverLicenseFile
    spokelogAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    useAzureFiles: false
    useCloudStorage: false
    windowsDomainAdministratorPassword: domainJoinPassword
    windowsDomainAdministratorUserName: domainJoinUsername
    windowsDomainName: domainName
  }
}
