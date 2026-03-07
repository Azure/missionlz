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

@description('The virtual machine size for the Azure Virtual Desktop session hosts.')
param virtualMachineSize string = 'Standard_NV4ads_V710_v5'

var firewallClientSubnetAddressPrefix = '10.0.128.0/26'
var firewallClientPrivateIpAddress = firewallClientUsableIpAddresses[3]
var firewallClientUsableIpAddresses = [for i in range(0, 4): cidrHost(firewallClientSubnetAddressPrefix, i)]
var networkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]
var subscriptionId = subscription().subscriptionId
var virtualNetworkDiagnosticsLogs = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]
var virtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

module networking '../../modules/networking.bicep' = {
  name: 'deploy-mlz-networking-${deploymentNameSuffix}'
  params: {
    bastionHostSubnetAddressPrefix: '10.0.128.192/26'
    azureGatewaySubnetAddressPrefix: '10.0.129.192/26'
    deployIdentity: true
    deploymentNameSuffix: deploymentNameSuffix
    deployBastion: true
    deployAzureGatewaySubnet: false
    dnsServers: ['168.63.129.16']
    enableProxy: true
    environmentAbbreviation: environmentAbbreviation
    firewallSettings: {
      clientPrivateIpAddress: firewallClientPrivateIpAddress
      clientPublicIPAddressAvailabilityZones: []
      clientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
      customPipCount: 0
      intrusionDetectionMode: 'Alert'
      managementPublicIPAddressAvailabilityZones: []
      managementSubnetAddressPrefix: '10.0.128.64/26'
      skuTier: 'Standard'
      supernetIPAddress: '10.0.128.0/18'
      threatIntelMode: 'Alert'
    }
    firewallRuleCollectionGroups: [
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
    identifier: identifier
    location: location
    networks: [
      {
        name: 'hub'
        shortName: 'hub'
        subscriptionId: subscriptionId
        nsgDiagLogs: networkSecurityGroupDiagnosticsLogs
        nsgRules: []
        vnetAddressPrefix: '10.0.128.0/23'
        vnetDiagLogs: virtualNetworkDiagnosticsLogs
        vnetDiagMetrics: virtualNetworkDiagnosticsMetrics
        subnetAddressPrefix: '10.0.128.128/26'
      }
      {
        name: 'operations'
        shortName: 'ops'
        subscriptionId: subscriptionId
        nsgDiagLogs: networkSecurityGroupDiagnosticsLogs
        nsgRules: []
        vnetAddressPrefix: '10.0.131.0/24'
        vnetDiagLogs: virtualNetworkDiagnosticsLogs
        vnetDiagMetrics: virtualNetworkDiagnosticsMetrics
        subnetAddressPrefix: '10.0.131.0/24'
      }
      {
        name: 'sharedServices'
        shortName: 'svcs'
        subscriptionId: subscriptionId
        nsgDiagLogs: networkSecurityGroupDiagnosticsLogs
        nsgRules: []
        vnetAddressPrefix: '10.0.132.0/24'
        vnetDiagLogs: virtualNetworkDiagnosticsLogs
        vnetDiagMetrics: virtualNetworkDiagnosticsMetrics
        subnetAddressPrefix: '10.0.132.0/24'
      }
      {
        name: 'identity'
        shortName: 'id'
        subscriptionId: subscriptionId
        nsgDiagLogs: networkSecurityGroupDiagnosticsLogs
        nsgRules: []
        vnetAddressPrefix: '10.0.130.0/24'
        vnetDiagLogs: virtualNetworkDiagnosticsLogs
        vnetDiagMetrics: virtualNetworkDiagnosticsMetrics
        subnetAddressPrefix: '10.0.130.0/24'
      }
    ]
    tags: tags
  }
}

module monitoring '../../modules/monitoring.bicep' = {
  name: 'deploy-mlz-monitoring-${deploymentNameSuffix}'
  params: {
    delimiter: networking.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    deploySentinel: false
    location: location
    logAnalyticsWorkspaceCappingDailyQuotaGb: -1
    logAnalyticsWorkspaceRetentionInDays: 30
    logAnalyticsWorkspaceSkuName: 'PerGB2018'
    privateDnsZoneResourceIds: networking.outputs.privateDnsZoneResourceIds
    mlzTags: networking.outputs.mlzTags
    tags: tags
    tier: filter(networking.outputs.tiers, tier => tier.name == 'operations')[0]
    tokens: networking.outputs.tokens
  }
}

module activeDirectoryDomainServices '../../modules/active-directory-domain-services.bicep' = {
  name: 'deploy-mlz-adds-${deploymentNameSuffix}'
  params: {
    adminPassword: domainAdministratorPassword
    adminUsername: domainAdministratorUsername
    delimiter: networking.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    domainName: addsDomainName
    environmentAbbreviation: environmentAbbreviation
    firewallPolicyResourceId: networking.outputs.firewallPolicyResourceId
    hybridUseBenefit: hybridUseBenefit
    imageOffer: 'WindowsServer'
    imagePublisher: 'MicrosoftWindowsServer'
    imageSku: '2022-datacenter-g2'
    imageVersion: 'latest'
    ipAddresses: [
      cidrHost('10.0.130.0/24', 5)
      cidrHost('10.0.130.0/24', 6)
    ]
    keyVaultPrivateDnsZoneResourceId: networking.outputs.privateDnsZoneResourceIds.keyVault
    location: location
    mlzTags: networking.outputs.mlzTags
    resourceAbbreviations: networking.outputs.resourceAbbreviations
    safeModeAdminPassword: domainAdministratorPassword
    tags: tags
    tiers: networking.outputs.tiers
    tokens: networking.outputs.tokens
    vmSize: addsVmSize
  }
}

module remoteAccess 'modules/remote-access.bicep' = {
  name: 'deploy-mlz-remote-access-${deploymentNameSuffix}'
  params: {
    bastionHostPublicIPAddressAllocationMethod: 'Static'
    bastionHostPublicIPAddressAvailabilityZones: []
    bastionHostPublicIPAddressSkuName: 'Standard'
    bastionHostSubnetResourceId: networking.outputs.bastionHostSubnetResourceId
    delimiter: networking.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    location: location
    mlzTags: networking.outputs.mlzTags
    tags: tags
    tier: filter(networking.outputs.tiers, tier => tier.name == 'hub')[0]
    tokens: networking.outputs.tokens
  }
}

module storage '../../modules/storage.bicep' = {
  name: 'deploy-diag-storage-${deploymentNameSuffix}'
  params: {
    delimiter: networking.outputs.delimiter
    //deployIdentity: deployIdentity
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    location: location
    logStorageSkuName: 'Standard_GRS'
    mlzTags: networking.outputs.mlzTags
    privateDnsZoneResourceIds: networking.outputs.privateDnsZoneResourceIds
    purpose: 'diag'
    resourceAbbreviations: networking.outputs.resourceAbbreviations
    tags: tags
    tiers: networking.outputs.tiers
    tokens: networking.outputs.tokens
  }
  dependsOn: [
    activeDirectoryDomainServices // This is needed to ensure the first two IPs in the identity subnet are availabile for the domain controllers
    remoteAccess
  ]
}

module diagnosticSettings '../../modules/diagnostic-settings.bicep' = {
  name: 'deploy-diagnostic-settings-${deploymentNameSuffix}'
  params: {
    bastionDiagnosticsLogs: [
      {
        category: 'BastionAuditLogs'
        enabled: true
      }
    ]
    bastionDiagnosticsMetrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    blobDiagnosticsLogs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    blobDiagnosticsMetrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    delimiter: networking.outputs.delimiter
    deployBastion: true
    deployNetworkWatcherTrafficAnalytics: true
    deploymentNameSuffix: deploymentNameSuffix
    fileDiagnosticsLogs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    fileDiagnosticsMetrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    firewallDiagnosticsLogs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
      {
        category: 'AZFWNetworkRule'
        enabled: true
      }
      {
        category: 'AZFWApplicationRule'
        enabled: true
      }
      {
        category: 'AZFWNatRule'
        enabled: true
      }
      {
        category: 'AZFWThreatIntel'
        enabled: true
      }
      {
        category: 'AZFWIdpsSignature'
        enabled: true
      }
      {
        category: 'AZFWDnsQuery'
        enabled: true
      }
      {
        category: 'AZFWFqdnResolveFailure'
        enabled: true
      }
      {
        category: 'AZFWFatFlow'
        enabled: true
      }
      {
        category: 'AZFWFlowTrace'
        enabled: true
      }
      {
        category: 'AZFWApplicationRuleAggregation'
        enabled: true
      }
      {
        category: 'AZFWNetworkRuleAggregation'
        enabled: true
      }
      {
        category: 'AZFWNatRuleAggregation'
        enabled: true
      }
    ]
    firewallDiagnosticsMetrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    keyVaults: [
      storage.outputs.keyVaultProperties
      activeDirectoryDomainServices.outputs.keyVaultProperties
    ]
    keyVaultDiagnosticLogs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
      }
    ]
    keyVaultDiagnosticMetrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    location: location
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    networkInterfaceDiagnosticsMetrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    networkInterfaceResourceIds: union(
      activeDirectoryDomainServices.outputs.networkInterfaceResourceIds,
      monitoring.outputs.networkInterfaceResourceIds
    )
    networkWatcherFlowLogsRetentionDays: 30
    networkWatcherFlowLogsType: 'VirtualNetwork'
    publicIPAddressDiagnosticsLogs: [
      {
        category: 'DDoSProtectionNotifications'
        enabled: true
      }
      {
        category: 'DDoSMitigationFlowLogs'
        enabled: true
      }
      {
        category: 'DDoSMitigationReports'
        enabled: true
      }
    ]
    publicIPAddressDiagnosticsMetrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    queueDiagnosticsLogs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    queueDiagnosticsMetrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    storageAccountDiagnosticsLogs: []
    storageAccountDiagnosticsMetrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    storageAccountResourceIds: storage.outputs.storageAccountResourceIds
    supportedClouds: [
      'AzureCloud'
      'AzureUSGovernment'
    ]
    tableDiagnosticsLogs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    tableDiagnosticsMetrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    tiers: networking.outputs.tiers
    tokens: networking.outputs.tokens
  }
}

module security '../../modules/security.bicep' = {
  name: 'deploy-security-${deploymentNameSuffix}'
  params: {
    defenderPlans: ['VirtualMachines']
    defenderSkuTier: 'Free'
    deployDefender: false
    deployPolicy: deployPolicy
    deploymentNameSuffix: deploymentNameSuffix
    emailSecurityContact: ''
    location: location
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    policy: policy
    tiers: networking.outputs.tiers
    windowsAdministratorsGroupMembership: domainAdministratorUsername
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
    virtualMachineResourceIds: activeDirectoryDomainServices.outputs.virtualMachineResourceIds
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
    environmentAbbreviation: environmentAbbreviation
    //fileShare: azureNetAppFiles.outputs.fileShare
    hubAzureFirewallResourceId: networking.outputs.azureFirewallResourceId
    hubStorageAccountResourceId: storage.outputs.storageAccountResourceIds[0]
    hubVirtualNetworkResourceId: networking.outputs.hubVirtualNetworkResourceId
    identifier: identifier
    location: location
    operationsLogAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    policy: policy
    privateLinkScopeResourceId: monitoring.outputs.privateLinkScopeResourceId
    securityPrincipals: securityPrincipals
    virtualMachineAdminPassword: domainAdministratorPassword
    virtualMachineAdminUsername: domainAdministratorUsername
    virtualMachineSize: virtualMachineSize
  }
}

module azureNetAppFiles '../azure-netapp-files/solution.bicep' = {
  name: 'deploy-azure-netapp-files-${deploymentNameSuffix}'
  params: {
    azureFirewallResourceId: networking.outputs.azureFirewallResourceId
    deployActivityLogDiagnosticSetting: true
    deployDefender: true
    deploymentNameSuffix: deploymentNameSuffix
    deployPolicy: deployPolicy
    domainAdminPassword: domainAdministratorPassword
    domainAdminUserPrincipalName: '${domainAdministratorUsername}@${addsDomainName}'
    domainName: addsDomainName
    environmentAbbreviation: environmentAbbreviation
    fileShareName: 'arcgispro'
    hubStorageAccountResourceId: storage.outputs.storageAccountResourceIds[0]
    hubVirtualNetworkResourceId: networking.outputs.hubVirtualNetworkResourceId
    identifier: identifier
    location: location
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    policy: policy
    securityPrincipalName: domainUserUsername
    sku: 'Standard'
    tags: tags
    virtualMachineAdminPassword: domainAdministratorPassword
    virtualMachineAdminUsername: domainAdministratorUsername
  }
  dependsOn: [
    azureVirtualDesktop
  ]
}
