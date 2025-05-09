targetScope = 'subscription'

@allowed([
  'ActiveDirectoryDomainServices'
  'MicrosoftEntraDomainServices'
  'MicrosoftEntraId'
  'MicrosoftEntraIdIntuneEnrollment'
])
@description('The service providing domain services for Azure Virtual Desktop.  This is needed to properly configure the session hosts and if applicable, the Azure Storage Account.')
param activeDirectorySolution string

@allowed([
  'AvailabilitySets'
  'AvailabilityZones'
  'None'
])
@description('The desired availability option when deploying a pooled host pool. The best practice is to deploy to availability zones for the highest resilency and service level agreement.')
param availability string = 'AvailabilityZones'

@description('The availability zones allowed for the AVD session hosts deployment location.')
param availabilityZones array = ['1', '2', '3']

@description('The file name for the ZIP file containing the AVD agents and DSC configuration.')
param avdConfigurationZipFileName string = 'Configuration_1.0.02990.697.zip'

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

@description('The subnet address prefix for the Azure NetApp Files delegated subnet.')
param azureNetAppFilesSubnetAddressPrefix string = ''

@description('The RDP properties to add or remove RDP functionality on the AVD host pool. The string must end with a semi-colon. Settings reference: https://learn.microsoft.com/windows-server/remote/remote-desktop-services/clients/rdp-files')
param customRdpProperty string = 'audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;encode redirected video capture:i:1;redirected video capture encoding quality:i:1;audiomode:i:0;devicestoredirect:s:;redirectclipboard:i:0;redirectcomports:i:0;redirectlocation:i:1;redirectprinters:i:0;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:;keyboardhook:i:2;'

@description('Choose whether to deploy a diagnostic setting for the Activity Log.')
param deployActivityLogDiagnosticSetting bool

@description('Choose whether to deploy Defender for Cloud.')
param deployDefender bool

@description('When set to true, deploys Network Watcher Traffic Analytics. It defaults to "false".')
param deployNetworkWatcherTrafficAnalytics bool = false

@description('Choose whether to deploy a policy assignment.')
param deployPolicy bool

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('The friendly name for the SessionDesktop application in the desktop application group.')
param desktopFriendlyName string = ''

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

@description('The email address to use for Defender for Cloud notifications.')
param emailSecurityContact string = ''

@description('Determine whether to enable accelerated networking on the AVD session hosts. https://learn.microsoft.com/en-us/azure/virtual-network/accelerated-networking-overview')
param enableAcceleratedNetworking bool

@description('Deploys the required resources to monitor the function app for the Auto Increase Premium File Share solutions.')
param enableApplicationInsights bool = true

@description('Deploys the required monitoring resources to enable AVD Insights.')
param enableAvdInsights bool = true

@description('Enable the partner telemetry deployment. This will allow ESRI to see data around the ArcGIS Pro deployments. https://learn.microsoft.com/en-us/partner-center/marketplace-offers/azure-partner-customer-usage-attribution')
param enableTelemetry bool = false

@description('Enables windows update services access through firewall.')
param enableWindowsUpdateFwRules bool = false

@allowed([
  'dev' // Development
  'prod' // Production
  'test' // Test
])
@description('The abbreviation for the target environment.')
param environmentAbbreviation string = 'dev'

@description('The resource ID for the existing feed workspace within a business unit or project.')
param existingFeedWorkspaceResourceId string = ''

@description('The custom firewall rule collection groups that override the default firewall rule collection groups.')
param customFirewallRuleCollectionGroups array = []

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
  'None' // Local Profiles
])
@description('Enable an Fslogix storage option to manage user profiles for the AVD session hosts. The selected service & SKU should provide sufficient IOPS for all of your users. https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#performance-requirements')
param fslogixStorageService string = 'AzureFiles Standard'

@description('The subnet address prefix for the delegated subnet for the Azure Function App. This subnet is required for the Auto Increase Premium File Share Quotas tool.')
param functionAppSubnetAddressPrefix string = ''

@allowed([
  'Disabled'
  'Enabled'
  'EnabledForClientsOnly'
  'EnabledForSessionHostsOnly'
])
@description('The type of public network access for the host pool.')
param hostPoolPublicNetworkAccess string = 'Enabled'

@allowed([
  'Pooled'
  'Personal'
])
@description('The type of AVD host pool.')
param hostPoolType string = 'Pooled'

@description('The resource ID for the Azure Firewall in the HUB subscription')
param hubAzureFirewallResourceId string

@description('The resource ID for the Azure Virtual Network in the HUB subscription.')
param hubVirtualNetworkResourceId string

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param identifier string = 'avd'

@description('Offer for the virtual machine image')
param imageOffer string = 'office-365'

@description('Publisher for the virtual machine image')
param imagePublisher string = 'MicrosoftWindowsDesktop'

@description('SKU for the virtual machine image')
param imageSku string = 'win11-22h2-avd-m365'

@description('The resource ID for the Compute Gallery Image Version. Do not set this value if using a marketplace image.')
param imageVersionResourceId string = ''

@description('An array of Key Vault Diagnostic Logs categories to collect. See "https://learn.microsoft.com/en-us/azure/key-vault/general/logging?tabs=Vault" for valid values.')
param keyVaultDiagnosticsLogs array = [
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

@description('The deployment location for the AVD sessions hosts. This is necessary when the users are closer to a different location than the control plane location.')
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

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param logStorageSkuName string = 'Standard_GRS'

@description('An array of metrics to enable on the diagnostic setting for network interfaces.')
param networkInterfaceDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

@description('An array of Network Security Group diagnostic logs to apply to the workload Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
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

@description('The rules to apply to the Network Security Group.')
param networkSecurityGroupRules array = []

@description('The number of days to retain Network Watcher Flow Logs. It defaults to "30".')  
param networkWatcherFlowLogsRetentionDays int = 30

@allowed([
  'NetworkSecurityGroup'
  'VirtualNetwork'
])
@description('When set to "true", enables Virtual Network Flow Logs. It defaults to "true" as its required by MCSB.')
param networkWatcherFlowLogsType string = 'VirtualNetwork'

@description('The resource ID for an existing network watcher for the desired deployment location. Only one network watcher per location can exist in a subscription. The value can be left empty to create a new network watcher resource.')
param networkWatcherResourceId string = ''

@description('The resource ID of the Log Analytics Workspace to use for log storage.')
param operationsLogAnalyticsWorkspaceResourceId string

@description('The distinguished name for the target Organization Unit in Active Directory Domain Services.')
param organizationalUnitPath string = ''

@description('The policy to assign to the workload.')
param policy string = 'NISTRev4'

@description('The resource ID for the Azure Monitor Private Link Scope in the Operations subscription / resource group.')
param privateLinkScopeResourceId string

@allowed([
  'ArcGISPro'
  'Generic'
])
@description('The profile of the workload for the AVD session hosts. When ArcGISPro is selected, telemetry data is collected for ESRI in the Partner Center.')
param profile string = 'Generic'

// @description('Enable backups to an Azure Recovery Services vault.  For a pooled host pool this will enable backups on the Azure file share.  For a personal host pool this will enable backups on the AVD sessions hosts.')
// param recoveryServices bool = false

@description('Off peak start time for weekdays in HH:mm format.')
param scalingWeekdaysOffPeakStartTime string = '17:00'

@description('Off peak start time for weekends in HH:mm format.')
param scalingWeekdaysPeakStartTime string = '09:00'

@description('Peak start time for weekdays in HH:mm format.')
param scalingWeekendsOffPeakStartTime string = '17:00'

@description('Peak start time for weekends in HH:mm format.')
param scalingWeekendsPeakStartTime string = '09:00'

@description('The array of Security Principals with their object IDs and display names to assign to the AVD Application Group and FSLogix Storage.')
param securityPrincipals array

/* Example of a security principal
[
  {
    displayName: 'AVD'
    objectId: '00000000-0000-0000-0000-000000000000'
  }
]
*/

@maxValue(5000)
@minValue(0)
@description('The number of session hosts to deploy in the host pool. Ensure you have the approved quota to deploy the desired count.')
param sessionHostCount int = 1

@maxValue(4999)
@minValue(0)
@description('The starting number for the session hosts. This is important when adding virtual machines to ensure an update deployment is not performed on an existing, active session host.')
param sessionHostIndex int = 0

@description('The resource ID for the subnet in the Shared Services subscription. This is required for the private endpoint on the AVD Global Workspace.')
param sharedServicesSubnetResourceId string

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

@minLength(1)
@maxLength(2)
@description('The address prefix(es) for the new subnet(s) that will be created in the spoke virtual network(s). Specify only one address prefix in the array if the session hosts location and the control plan location are the same. If different locations are specified, add a second address prefix for the hosts virtual network.')
param subnetAddressPrefixes array = [
  '10.0.1${40 + (2 * stampIndex)}.0/24'
  '10.0.1${41 + (2 * stampIndex)}.0/26'
]

@description('The Key / value pairs of metadata for the Azure resource groups and resources.')
param tags object = {}

@description('The number of users per core is used to determine the maximum number of users per session host.')
param usersPerCore int = 1

@description('The validation environment setting on the AVD host pool determines whether the hostpool should receive AVD preview features for testing.')
param validationEnvironment bool = false

@secure()
@description('The local administrator password for the AVD session hosts')
param virtualMachineAdminPassword string

@description('The local administrator username for the AVD session hosts')
param virtualMachineAdminUsername string

@description('The virtual machine SKU for the AVD session hosts.')
param virtualMachineSize string = 'Standard_D4ads_v5'

@description('The number of virtual CPUs per virtual machine for the selected virtual machine size.')
param virtualMachineVirtualCpuCount int

@minLength(1)
@maxLength(2)
@description('The address prefix for the new spoke virtual network(s). Specify only one address prefix in the array if the session hosts location and the control plan location are the same. If different locations are specified, add a second address prefix for the hosts virtual network.')
param virtualNetworkAddressPrefixes array = [
  '10.0.1${40 + (2 * stampIndex)}.0/23'
]

@description('The diagnostic logs to apply to the workload Virtual Network.')
param virtualNetworkDiagnosticsLogs array = []

@description('The metrics to monitor for the workload Virtual Network.')
param virtualNetworkDiagnosticsMetrics array = []

@description('The friendly name for the AVD workspace that is displayed in the end-user client.')
param workspaceFriendlyName string = ''

@allowed([
  'Disabled'
  'Enabled'
])
@description('The public network access setting on the AVD workspace either disables public network access or allows both public and private network access.')
param workspacePublicNetworkAccess string = 'Enabled'

//  BATCH SESSION HOSTS
// The following variables are used to determine the batches to deploy any number of AVD session hosts.
var maxResourcesPerTemplateDeployment = 88 // This is the max number of session hosts that can be deployed from the sessionHosts.bicep file in each batch / for loop. Math: (800 - <Number of Static Resources>) / <Number of Looped Resources> 
var divisionValue = sessionHostCount / maxResourcesPerTemplateDeployment // This determines if any full batches are required.
var divisionRemainderValue = sessionHostCount % maxResourcesPerTemplateDeployment // This determines if any partial batches are required.
var sessionHostBatchCount = divisionRemainderValue > 0 ? divisionValue + 1 : divisionValue // This determines the total number of batches needed, whether full and / or partial.

//  BATCH AVAILABILITY SETS
// The following variables are used to determine the number of availability sets.
var maxAvSetMembers = 200 // This is the max number of session hosts that can be deployed in an availability set.
var beginAvSetRange = sessionHostIndex / maxAvSetMembers // This determines the availability set to start with.
var endAvSetRange = (sessionHostCount + sessionHostIndex) / maxAvSetMembers // This determines the availability set to end with.
var availabilitySetsCount = length(range(beginAvSetRange, (endAvSetRange - beginAvSetRange) + 1))

// OTHER LOGIC & COMPUTED VALUES
var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')
var customImageId = empty(imageVersionResourceId) ? 'null' : '"${imageVersionResourceId}"'
var deployFslogix = contains(fslogixStorageService, 'Azure') && contains(activeDirectorySolution, 'DomainServices')
  ? true
  : false
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
var fileShares = fileShareNames[fslogixContainerType]
var netbios = split(domainName, '.')[0]
var privateDnsZoneResourceIdPrefix = '/subscriptions/${split(hubVirtualNetworkResourceId, '/')[2]}/resourceGroups/${split(hubVirtualNetworkResourceId, '/')[4]}/providers/Microsoft.Network/privateDnsZones/'
var privateDnsZoneSuffixes_AzureVirtualDesktop = {
  AzureCloud: 'microsoft.com'
  AzureUSGovernment: 'azure.us'
}
var stampIndexFull = padLeft(stampIndex, 2, '0')
var storageSku = fslogixStorageService == 'None' ? 'None' : split(fslogixStorageService, ' ')[1]
var storageService = split(fslogixStorageService, ' ')[0]
var storageSuffix = environment().suffixes.storage
var subnets = {
  avdControlPlane: [
    {
      name: 'AvdControlPlane'
      properties: {
        addressPrefix: subnetAddressPrefixes[1]
      }
    }
  ]
  azureNetAppFiles: contains(fslogixStorageService, 'AzureNetAppFiles') && !empty(azureNetAppFilesSubnetAddressPrefix)
    ? [
        {
          name: 'AzureNetAppFiles'
          properties: {
            addressPrefix: azureNetAppFilesSubnetAddressPrefix
          }
        }
      ]
    : []
  functionApp: fslogixStorageService == 'AzureFiles Premium'
    ? [
        {
          name: 'FunctionAppOutbound'
          properties: {
            addressPrefix: functionAppSubnetAddressPrefix
          }
        }
      ]
    : []
}

// Gets the MLZ hub virtual network for its location and tags
resource virtualNetwork_hub 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(hubVirtualNetworkResourceId, '/')[8]
  scope: resourceGroup(split(hubVirtualNetworkResourceId, '/')[2], split(hubVirtualNetworkResourceId, '/')[4])
}

module virtualNetwork_identity '../../modules/existing-vnet-address-prefix.bicep' = if (contains(activeDirectorySolution, 'DomainServices')) {
  name: 'get-id-vnet-${deploymentNameSuffix}'
  params: {
    networkName: 'identity'
    peerings: virtualNetwork_hub.properties.virtualNetworkPeerings
  }
}

module virtualNetwork_operations '../../modules/existing-vnet-address-prefix.bicep' = {
  name: 'get-ops-vnet-${deploymentNameSuffix}'
  params: {
    networkName: 'operations'
    peerings: virtualNetwork_hub.properties.virtualNetworkPeerings
  }
}

// Gets the application group references if the AVD feed workspace already exists
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' existing = if (!empty(existingFeedWorkspaceResourceId)) {
  scope: resourceGroup(split(existingFeedWorkspaceResourceId, '/')[2], split(existingFeedWorkspaceResourceId, '/')[4])
  name: split(existingFeedWorkspaceResourceId, '/')[8]
}

// Optionally deploys telemetry for ArcGIS Pro deployments
#disable-next-line no-deployments-resources
resource partnerTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry && profile == 'ArcGISPro') {
  name: 'pid-4e82be1d-7fcb-4913-a90c-aa84d7ea3a1c'
  location: locationVirtualMachines
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

// Gets the naming convention for the resource groups and resources
module naming_management '../../modules/naming-convention.bicep' = {
  name: 'get-naming-mgmt-${deploymentNameSuffix}'
  params: {
    environmentAbbreviation: environmentAbbreviation
    location: virtualNetwork_hub.location
    networkName: 'avd'
    identifier: identifier
  }
}

module tier3_hosts '../tier3/solution.bicep' = {
  name: 'deploy-tier3-avd-${deploymentNameSuffix}'
  params: {
    additionalSubnets: union(subnets.avdControlPlane, subnets.azureNetAppFiles, subnets.functionApp)
    customFirewallRuleCollectionGroups: empty(customFirewallRuleCollectionGroups) ? [
      {
        name: 'AVD-CollapsedCollectionGroup-Stamp-${stampIndex}'
        properties: {
          priority: 200
          ruleCollections: [
            {
              name: 'ApplicationRules'
              priority: 150
              ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
              action: {
                type: 'Allow'
              }
              rules: concat(
                [
                  {
                    name: 'AVD-RequiredDeploymentEndpoints'
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
                      replace(environment().resourceManager, 'https://', '')
                      'mrsglobalsteus2prod.blob.${environment().suffixes.storage}'
                      'wvdportalstorageblob.blob.${environment().suffixes.storage}'
                      'gcs.prod.monitoring.${environment().suffixes.storage}'
                      '*.prod.warm.ingest.monitor.${environment().suffixes.storage}'
                      '*.guestconfiguration.${privateDnsZoneSuffixes_AzureVirtualDesktop[?environment().name] ?? cloudSuffix}'
                      '*.wvd.${privateDnsZoneSuffixes_AzureVirtualDesktop[?environment().name] ?? cloudSuffix}'
                    ]
                    targetUrls: []
                    terminateTLS: false
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: []
                    sourceIpGroups: []
                  }
                ],
                contains(activeDirectorySolution, 'MicrosoftEntraId') ? [
                  {
                    name: 'AVD-EntraAuthEndpoints'
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
                      replace(environment().authentication.loginEndpoint, 'https://', '')
                      replace(environment().graph, 'https://', '')
                      'enterpriseregistration.windows.net'
                    ]
                    targetUrls: []
                    terminateTLS: false
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: []
                    sourceIpGroups: []
                  }
                ] : [],
                enableWindowsUpdateFwRules ? [
                  {
                    name: 'WindowsUpdateEndpoints'
                    ruleType: 'ApplicationRule'
                    protocols: [
                      {
                        protocolType: 'Https'
                        port: 443
                      }
                      {
                        protocolType: 'Http'
                        port: 80
                      }
                    ]
                    fqdnTags: [
                      'WindowsUpdate'
                    ]
                    webCategories: []
                    targetFqdns: []
                    targetUrls: []
                    terminateTLS: false
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: []
                    sourceIpGroups: []
                  }
                ] : []
              )
            }
            {
              name: 'NetworkRules'
              priority: 140
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
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: []
                    destinationFqdns: [
                      'azkms.${environment().suffixes.storage}'
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
                    name: 'AllowMonitorToLAW'
                    ruleType: 'NetworkRule'
                    ipProtocols: ['Tcp']
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: [cidrHost(virtualNetwork_operations.outputs.addressPrefix, 3)] // Network of the Log Analytics Workspace, could be narrowed using parameters file post deployment
                    destinationPorts: ['443'] // HTTPS port for Azure Monitor
                    sourceIpGroups: []
                    destinationIpGroups: []
                    destinationFqdns: []
                  }
                ],
                [
                  {
                    name: 'TimeSync'
                    ruleType: 'NetworkRule'
                    ipProtocols: [
                      'Udp'
                    ]
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: []
                    destinationFqdns: [
                      'time.windows.com'
                    ]
                    destinationPorts: [
                      '123'
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
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: ['AzureActiveDirectory']
                    destinationFqdns: []
                    destinationPorts: [
                      '443'
                    ]
                    sourceIpGroups: []
                    destinationIpGroups: []
                  }
                ],
                contains(activeDirectorySolution, 'DomainServices') ? [
                  {
                    name: 'ADCommunicationRule'
                    ruleType: 'NetworkRule'
                    ipProtocols: [
                      'Tcp'
                      'Udp'
                    ]
                    sourceAddresses: virtualNetworkAddressPrefixes
                    destinationAddresses: [
                      virtualNetwork_identity.outputs.addressPrefix
                    ]
                    destinationPorts: [
                      '53'
                      '88'
                      '389'
                      '445'
                      '139'
                      '135'
                      '89'
                      '123'
                      '1024-65535'
                    ]
                    sourceIpGroups: []
                    destinationIpGroups: []
                  }
                ] : []
              )
            }
          ]
        }
      }
    ] : customFirewallRuleCollectionGroups
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deploymentNameSuffix: deploymentNameSuffix
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    deployPolicy: deployPolicy
    emailSecurityContact: emailSecurityContact
    environmentAbbreviation: environmentAbbreviation
    firewallResourceId: hubAzureFirewallResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    identifier: identifier
    keyVaultDiagnosticLogs: keyVaultDiagnosticsLogs
    keyVaultDiagnosticMetrics: keyVaultDiagnosticMetrics
    location: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: operationsLogAnalyticsWorkspaceResourceId
    logStorageSkuName: logStorageSkuName
    networkInterfaceDiagnosticsMetrics: networkInterfaceDiagnosticsMetrics
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    networkWatcherResourceId: networkWatcherResourceId
    policy: policy
    subnetAddressPrefix: subnetAddressPrefixes[0]
    subnetName: 'AvdSessionHosts'
    tags: tags
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefixes[0]
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics
    windowsAdministratorsGroupMembership: virtualMachineAdminUsername
    workloadName: 'avd'
    workloadShortName: 'avd'
  }
}

// Shared
// This module creates the resources that are be shared across multiple AVD stamps: 
// - global and feed AVD workspace to support AVD with Private Link
// - log analytics workspace and data collection rule for AVD Insights
module shared 'modules/shared/shared.bicep' = {
  name: 'deploy-workspaces-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    delimiter: naming_management.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    existingApplicationGroupReferences: empty(existingFeedWorkspaceResourceId)
      ? []
      : workspace.properties.applicationGroupReferences
    existingFeedWorkspaceResourceId: existingFeedWorkspaceResourceId
    locationControlPlane: virtualNetwork_hub.location
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: tier3_hosts.outputs.mlzTags
    names: naming_management.outputs.names
    sharedServicesSubnetResourceId: sharedServicesSubnetResourceId
    tags: tags
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    fslogixStorageService: fslogixStorageService
    existingWorkspace: !empty(existingFeedWorkspaceResourceId)
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: tier3_hosts.outputs.privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupFslogix: '${naming_management.outputs.names.resourceGroup}${naming_management.outputs.delimiter}fslogix'
    resourceGroupManagement: '${naming_management.outputs.names.resourceGroup}${naming_management.outputs.delimiter}management'
    stampIndexFull: stampIndexFull
    subnetResourceId: tier3_hosts.outputs.subnets[0].id
    subnets: tier3_hosts.outputs.subnets
  }
}

// Management: host pool, app group, AVD Insights, File Share Scaling
module management 'modules/management/management.bicep' = {
  name: 'deploy-management-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdObjectId: avdObjectId
    avdPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(tier3_hosts.outputs.privateDnsZones, name => startsWith(name, 'privatelink.wvd'))[0]}'
    customImageId: customImageId
    customRdpProperty: customRdpProperty
    delimiter: tier3_hosts.outputs.delimiter
    // deployFslogix: deployFslogix
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: shared.outputs.deploymentUserAssignedIdentityClientId
    deploymentUserAssignedIdentityPrincipalId: shared.outputs.deploymentUserAssignedIdentityPrincipalId
    deploymentUserAssignedIdentityResourceId: shared.outputs.deploymentUserAssignedIdentityResourceId
    desktopFriendlyName: empty(desktopFriendlyName) ? string(stampIndex) : desktopFriendlyName
    diskAccessPolicyDefinitionId: shared.outputs.diskAccessPolicyDefinitionId
    diskAccessPolicyDisplayName: shared.outputs.diskAccessPolicyDisplayName
    diskAccessResourceId: shared.outputs.diskAccessResourceId
    diskEncryptionSetResourceId: tier3_hosts.outputs.diskEncryptionSetResourceId
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableAvdInsights: enableAvdInsights
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    imageVersionResourceId: imageVersionResourceId
    locationControlPlane: virtualNetwork_hub.location
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: shared.outputs.logAnalyticsWorkspaceResourceId
    maxSessionLimit: usersPerCore * virtualMachineVirtualCpuCount
    mlzTags: tier3_hosts.outputs.mlzTags
    namingConvention: tier3_hosts.outputs.namingConvention
    organizationalUnitPath: organizationalUnitPath
    // recoveryServices: recoveryServices
    // recoveryServicesGeo: tier3_hosts.outputs.locationProperties.recoveryServicesGeo
    resourceGroupManagement: '${naming_management.outputs.names.resourceGroup}${naming_management.outputs.delimiter}management'
    securityPrincipalObjectIds: map(securityPrincipals, item => item.objectId)
    sessionHostNamePrefix: tier3_hosts.outputs.namingConvention.virtualMachine
    stampIndexFull: stampIndexFull
    // storageService: storageService
    subnetResourceId: tier3_hosts.outputs.subnets[0].id
    tags: tags
    // timeZone: tier3_hosts.outputs.locationProperties.timeZone
    validationEnvironment: validationEnvironment
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
  }
}

module workspaces 'modules/shared/workspaces.bicep' = {
  name: 'deploy-workspaces-${deploymentNameSuffix}'
  params: {
    applicationGroupResourceId: management.outputs.applicationGroupResourceId
    avdPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(tier3_hosts.outputs.privateDnsZones, name => startsWith(name, 'privatelink.wvd'))[0]}'
    delimiter: tier3_hosts.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: shared.outputs.deploymentUserAssignedIdentityClientId
    enableAvdInsights: enableAvdInsights
    existingFeedWorkspaceResourceId: existingFeedWorkspaceResourceId
    hostPoolName: management.outputs.hostPoolName
    identifier: identifier
    identifierHub: virtualNetwork_hub.tags.identifier
    locationControlPlane: virtualNetwork_hub.location
    locationHub: virtualNetwork_hub.location
    locationVirtualMachines: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: shared.outputs.logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: management.outputs.virtualMachineName
    mlzTags: tier3_hosts.outputs.mlzTags
    names: naming_management.outputs.names
    resourceGroupManagement: management.outputs.resourceGroupName
    sharedServicesSubnetResourceId: sharedServicesSubnetResourceId
    tags: tags
    workspaceFriendlyName: workspaceFriendlyName
    workspaceGlobalPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(tier3_hosts.outputs.privateDnsZones, name => startsWith(name, 'privatelink-global.wvd'))[0]}'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

module fslogix 'modules/fslogix/fslogix.bicep' = if (deployFslogix) {
  name: 'deploy-fslogix-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    azureFilesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(tier3_hosts.outputs.privateDnsZones, name => contains(name, 'file'))[0]}'
    delimiter: tier3_hosts.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: shared.outputs.deploymentUserAssignedIdentityClientId
    deploymentUserAssignedIdentityPrincipalId: shared.outputs.deploymentUserAssignedIdentityPrincipalId
    dnsServers: join(tier3_hosts.outputs.dnsServers, ',')
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    encryptionUserAssignedIdentityResourceId: tier3_hosts.outputs.userAssignedIdentityResourceId
    fileShares: fileShares
    fslogixContainerType: fslogixContainerType
    fslogixShareSizeInGB: fslogixShareSizeInGB
    fslogixStorageService: fslogixStorageService
    functionAppPrincipalId: shared.outputs.functionAppPrincipalId
    hostPoolResourceId: management.outputs.hostPoolResourceId
    keyVaultUri: tier3_hosts.outputs.keyVaultUri
    location: locationVirtualMachines
    managementVirtualMachineName: management.outputs.virtualMachineName
    mlzTags: tier3_hosts.outputs.mlzTags
    namingConvention: tier3_hosts.outputs.namingConvention
    netbios: netbios
    organizationalUnitPath: organizationalUnitPath
    // recoveryServices: recoveryServices
    resourceGroupManagement: management.outputs.resourceGroupName
    resourceGroupName: tier3_hosts.outputs.namingConvention.resourceGroup
    securityPrincipalNames: map(securityPrincipals, item => item.displayName)
    securityPrincipalObjectIds: map(securityPrincipals, item => item.objectId)
    stampIndexFull: stampIndexFull
    storageCount: storageCount
    storageEncryptionKeyName: tier3_hosts.outputs.storageEncryptionKeyName
    storageIndex: storageIndex
    storageService: storageService
    storageSku: storageSku
    subnetResourceId: tier3_hosts.outputs.subnets[0].id
    subnets: tier3_hosts.outputs.subnets
    tags: tags
  }
}

module sessionHosts 'modules/session-hosts/session-hosts.bicep' = {
  name: 'deploy-session-hosts-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    availability: availability
    availabilitySetsCount: availabilitySetsCount
    availabilitySetsIndex: beginAvSetRange
    availabilityZones: availabilityZones
    avdConfigurationZipFileName: avdConfigurationZipFileName
    dataCollectionRuleResourceId: shared.outputs.dataCollectionRuleResourceId
    delimiter: tier3_hosts.outputs.delimiter
    deployFslogix: deployFslogix
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: shared.outputs.deploymentUserAssignedIdentityClientId
    deploymentUserAssignedIdentityPrincipalId: shared.outputs.deploymentUserAssignedIdentityPrincipalId
    diskAccessPolicyDefinitionId: shared.outputs.diskAccessPolicyDefinitionId
    diskAccessPolicyDisplayName: shared.outputs.diskAccessPolicyDisplayName
    diskAccessResourceId: shared.outputs.diskAccessResourceId
    diskEncryptionSetResourceId: tier3_hosts.outputs.diskEncryptionSetResourceId
    diskSku: diskSku
    divisionRemainderValue: divisionRemainderValue
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    drainMode: drainMode
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableAvdInsights: enableAvdInsights
    // enableRecoveryServices: recoveryServices
    enableWindowsUpdate: enableWindowsUpdateFwRules
    environmentAbbreviation: environmentAbbreviation
    fslogixContainerType: fslogixContainerType
    hostPoolName: management.outputs.hostPoolName
    hostPoolResourceId: management.outputs.hostPoolResourceId
    hostPoolType: hostPoolType
    identifier: identifier
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    imageVersionResourceId: imageVersionResourceId
    location: locationVirtualMachines
    logAnalyticsWorkspaceResourceId: shared.outputs.logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: management.outputs.virtualMachineName
    maxResourcesPerTemplateDeployment: maxResourcesPerTemplateDeployment
    mlzTags: tier3_hosts.outputs.mlzTags
    namingConvention: tier3_hosts.outputs.namingConvention
    netAppFileShares: deployFslogix ? fslogix.outputs.netAppShares : [
      'None'
    ]
    networkSecurityGroupResourceId: tier3_hosts.outputs.networkSecurityGroupResourceId
    organizationalUnitPath: organizationalUnitPath
    profile: profile
    // recoveryServicesVaultName: management.outputs.recoveryServicesVaultName
    resourceGroupManagement: management.outputs.resourceGroupName
    resourceGroupName: '${tier3_hosts.outputs.namingConvention.resourceGroup}${tier3_hosts.outputs.delimiter}hosts'
    scalingWeekdaysOffPeakStartTime: scalingWeekdaysOffPeakStartTime
    scalingWeekdaysPeakStartTime: scalingWeekdaysPeakStartTime
    scalingWeekendsOffPeakStartTime: scalingWeekendsOffPeakStartTime
    scalingWeekendsPeakStartTime: scalingWeekendsPeakStartTime
    securityPrincipalObjectIds: map(securityPrincipals, item => item.objectId)
    sessionHostBatchCount: sessionHostBatchCount
    sessionHostIndex: sessionHostIndex
    stampIndexFull: stampIndexFull
    storageAccountNamePrefix: deployFslogix ? fslogix.outputs.storageAccountNamePrefix : ''
    storageCount: storageCount
    storageIndex: storageIndex
    storageService: storageService
    storageSuffix: storageSuffix
    subnetResourceId: tier3_hosts.outputs.subnets[0].id
    tags: tags
    timeZone: tier3_hosts.outputs.locationProperties.timeZone
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
  }
}

module cleanUp 'modules/clean-up/clean-up.bicep' = {
  name: 'deploy-clean-up-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    location: locationVirtualMachines
    resourceGroupManagement: management.outputs.resourceGroupName
    userAssignedIdentityClientId: shared.outputs.deploymentUserAssignedIdentityClientId
    virtualMachineResourceId: management.outputs.virtualMachineResourceId
  }
  dependsOn: [
    fslogix
    sessionHosts
  ]
}
