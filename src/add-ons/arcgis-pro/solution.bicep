targetScope = 'subscription'

// @secure()
// @description('The Azure Active Directory Graph API access token with sufficient permissions to deploy Entra Cloud Sync. Refer to the documentation to get this value. It is only supported in AzureCloud / Commercial.')
// param aadGraphAccessToken string = ''

@description('The root domain name for the new forest in Active Directory Domain Services. Required when deployActiveDirectoryDomainServices is true.')
param addsDomainName string

@description('The virtual machine size for the Active Directory Domain Services (ADDS) domain controllers.')
param addsVmSize string = 'Standard_D2s_v3'

// @secure()
// @description('The password for the ArcGIS service account.')
// param arcgisServiceAccountPassword string

// @description('The username for the ArcGIS service account.')
// param arcgisServiceAccountUsername string

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

@description('The suffix used for naming deployments uniquely. It defaults to a timestamp with the utcNow function.')
param deploymentNameSuffix string = utcNow()

@description('Choose whether to deploy a policy assignment.')
param deployPolicy bool

@secure()
@description('The password for the domain administrator account.')
param domainAdministratorPassword string

@description('The username for the domain administrator account.')
param domainAdministratorUsername string

@secure()
@description('The password for the domain user account.')
param domainUserPassword string

@description('The username for the domain user account.')
param domainUserUsername string

@allowed([
  'dev'
  'prod'
  'test'
])
@description('[dev/prod/test] The abbreviation for the target environment.')
param environmentAbbreviation string = 'dev'

@description('Determines whether to use the hybrid use benefit for the Windows virtual machines.')
param hybridUseBenefit bool

@minLength(1)
@maxLength(3)
@description('1-3 alphanumeric characters without whitespace, used to name resources and generate uniqueness for resources within your subscription. Ideally, the value should represent an organization, department, or business unit.')
param identifier string

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@allowed([
  'NISTRev4'
  'NISTRev5'
  'IL5' // AzureUsGoverment only, trying to deploy IL5 in AzureCloud will switch to NISTRev4
  'CMMC'
])
@description('[NISTRev4/NISTRev5/IL5/CMMC] Built-in policy assignments to assign, Default value = "NISTRev4". IL5 is only available for AzureUsGovernment and will switch to NISTRev4 if tried in AzureCloud.')
param policy string = 'NISTRev4'

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

// @description('The client ID for the user assigned managed identity assigned to the domain controllers. The identity is required to deploy and configure Entra Cloud Sync.')
// param userAssignedManagedIdentityClientId string

module missionLandingZone '../../mlz.bicep' = {
  name: 'deploy-mission-landing-zone-${deploymentNameSuffix}'
  params: {
    addsDomainName: addsDomainName
    addsSafeModeAdminPassword: domainAdministratorPassword
    addsAdministratorPassword: domainAdministratorPassword
    addsAdministratorUsername: domainAdministratorUsername
    addsVmImageSku: '2022-datacenter-g2'
    addsVmSize: addsVmSize
    customFirewallRuleCollectionGroups: [
      {
        name: 'MLZ-DefaultCollectionGroup'
        properties: {
          priority: 100
          ruleCollections: [
            {
              name: 'NetworkRules'
              priority: 100
              ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
              action: {
                type: 'Allow'
              }
              rules: [
                {
                  name: 'Allow-Any-Any'
                  ruleType: 'NetworkRule'
                  ipProtocols: ['Any']
                  sourceAddresses: ['*']
                  destinationAddresses: ['*']
                  destinationPorts: ['*']
                }
              ]
            }
            {
              name: 'ApplicationRules'
              priority: 200
              ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
              action: {
                type: 'Allow'
              }
              rules: []
            }
          ]
        }
      }
    ]
    deployActiveDirectoryDomainServices: true
    deployBastion: true
    deployIdentity: true
    deployNetworkWatcherTrafficAnalytics: true
    environmentAbbreviation: environmentAbbreviation
    firewallSkuTier: 'Standard'
    hybridUseBenefit: hybridUseBenefit
    identifier: identifier
    location: location
    policy: policy
    tags: tags
  }
}

// Commented out Entra Cloud Sync automation until complete
// module entraCloudSync 'modules/entra-cloud-sync.bicep' = {
//   name: 'deploy-entra-cloud-sync-${deploymentNameSuffix}'
//   params: {
//     accessToken: aadGraphAccessToken
//     adminPassword: virtualMachineAdminPassword
//     adminUsername: virtualMachineAdminUsername
//     deploymentNameSuffix: deploymentNameSuffix
//     domainName: addsDomainName
//     location: location
//     mlzTags: missionLandingZone.outputs.mlzTags
//     tags: tags
//     userAssignedManagedIdentityClientId: userAssignedManagedIdentityClientId
//     virtualMachineResourceIds: missionLandingZone.outputs.domainControllerResourceIds
//   }
// }

module domainUserAccount 'modules/domain-user-account.bicep' = {
  name: 'deploy-domain-user-account-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    domainUserPassword: domainUserPassword
    domainUserUsername: domainUserUsername
    location: location
    tags: tags
    virtualMachineResourceIds: missionLandingZone.outputs.domainControllerResourceIds
  }
}

module azureVirtualDesktop 'modules/azure-virtual-desktop.bicep' = {
  name: 'deploy-azure-virtual-desktop-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: 'MicrosoftEntraId'
    avdObjectId: avdObjectId
    deployActivityLogDiagnosticSetting: true
    deployDefender: true
    deployPolicy: deployPolicy
    enableAcceleratedNetworking: true
    environmentAbbreviation: environmentAbbreviation
    fslogixStorageService: 'None'
    hubAzureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    hubStorageAccountResourceId: missionLandingZone.outputs.hubStorageAccountResourceId
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    identifier: identifier
    location: location
    operationsLogAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    policy: policy
    privateLinkScopeResourceId: missionLandingZone.outputs.privateLinkScopeResourceId
    securityPrincipals: securityPrincipals
    sharedServicesSubnetResourceId: missionLandingZone.outputs.sharedServicesSubnetResourceId
    usersPerCore: 1
    virtualMachineAdminPassword: domainAdministratorPassword
    virtualMachineAdminUsername: domainAdministratorUsername
    virtualMachineSize: 'Standard_NV4ads_V710_v5'
    virtualMachineVirtualCpuCount: 4
  }
}

module azureNetAppFiles '../azure-netapp-files/solution.bicep' = {
  name: 'deploy-azure-netapp-files-${deploymentNameSuffix}'
  params: {
    azureFirewallResourceId: missionLandingZone.outputs.azureFirewallResourceId
    deployActivityLogDiagnosticSetting: true
    deployDefender: true
    deploymentNameSuffix: deploymentNameSuffix
    deployPolicy: deployPolicy
    domainJoinPassword: domainAdministratorPassword
    domainJoinUserPrincipalName: '${domainAdministratorUsername}@${addsDomainName}'
    domainName: addsDomainName
    environmentAbbreviation: environmentAbbreviation
    fileShareName: 'arcgispro'
    hubStorageAccountResourceId: missionLandingZone.outputs.hubStorageAccountResourceId
    hubVirtualNetworkResourceId: missionLandingZone.outputs.hubVirtualNetworkResourceId
    identifier: identifier
    location: location
    logAnalyticsWorkspaceResourceId: missionLandingZone.outputs.logAnalyticsWorkspaceResourceId
    policy: policy
    sku: 'Standard'
    tags: tags
  }
}

// Commented out ArcGIS Enterprise deployment until ready
/* module arcGisEnterprise '../esri-enterprise/solution.bicep' = {
  name: 'deploy-esri-enterprise-${deploymentNameSuffix}'
  params: {
    adminPassword: domainAdministratorPassword
    adminUsername: domainAdministratorUsername
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
    windowsDomainAdministratorPassword: domainAdministratorPassword
    windowsDomainAdministratorUserName: domainAdministratorUsername
    windowsDomainName: domainName
  }
} */
