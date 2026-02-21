targetScope = 'subscription'

@allowed([
  'ActiveDirectoryDomainServices'
  'MicrosoftEntraDomainServices'
  'MicrosoftEntraId'
  'MicrosoftEntraIdIntuneEnrollment'
])
@description('The service providing domain services for Azure Virtual Desktop.  This is needed to properly configure the session hosts and if applicable, the Azure Storage Account.')
param activeDirectorySolution string

@description('The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID.')
param avdObjectId string

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

@description('The name of the domain that provides ADDS to the AVD session hosts.')
param domainName string = ''

@description('The email address to use for Defender for Cloud notifications.')
param emailSecurityContact string = ''

@allowed([
  'dev' // Development
  'prod' // Production
  'test' // Test
])
@description('The abbreviation for the target environment.')
param environmentAbbreviation string = 'dev'

@description('The file share on Azure NetApp Files to store unstructured geospatial data.')
param fileShare string

@allowed([
  'Disabled'
  'Enabled'
  'EnabledForClientsOnly'
  'EnabledForSessionHostsOnly'
])
@description('The type of public network access for the host pool.')
param hostPoolPublicNetworkAccess string = 'Enabled'

@description('The resource ID for the Azure Firewall in the HUB subscription')
param hubAzureFirewallResourceId string

@description('The resource ID for the Storage Account in the HUB subscription.')
param hubStorageAccountResourceId string

@description('The resource ID for the Azure Virtual Network in the HUB subscription.')
param hubVirtualNetworkResourceId string

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param identifier string = 'avd'

@description('The deployment location for the AVD sessions hosts. This is necessary when the users are closer to a different location than the control plane location.')
param location string = deployment().location

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

@description('The address prefix(es) for the new subnet(s) that will be created in the spoke virtual network(s). Specify only one address prefix in the array if the session hosts location and the control plan location are the same. If different locations are specified, add a second address prefix for the hosts virtual network.')
param managementSubnetAddressPrefix string = '10.0.141.0/26'

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

@description('The resource ID of the Log Analytics Workspace to use for log storage.')
param operationsLogAnalyticsWorkspaceResourceId string

@description('The policy to assign to the workload.')
param policy string = 'NISTRev4'

@description('The resource ID for the Azure Monitor Private Link Scope in the Operations subscription / resource group.')
param privateLinkScopeResourceId string

@description('The array of Security Principals with their object IDs and display names to assign to the AVD Application Group and FSLogix Storage.')
param securityPrincipals array

@description('The address prefix(es) for the new subnet(s) that will be created in the spoke virtual network(s). Specify only one address prefix in the array if the session hosts location and the control plan location are the same. If different locations are specified, add a second address prefix for the hosts virtual network.')
param sessionHostsSubnetAddressPrefix string = '10.0.140.0/24'

@description('The address prefix for the new spoke virtual network(s). Specify only one address prefix in the array if the session hosts location and the control plan location are the same. If different locations are specified, add a second address prefix for the hosts virtual network.')
param stampVirtualNetworkAddressPrefix string = '10.0.140.0/23'

@description('The Key / value pairs of metadata for the Azure resource groups and resources.')
param tags object = {}

@secure()
@description('The local administrator password for the AVD session hosts')
param virtualMachineAdminPassword string

@description('The local administrator username for the AVD session hosts')
param virtualMachineAdminUsername string

@description('The virtual machine SKU for the AVD session hosts.')
param virtualMachineSize string = 'Standard_D4ads_v5'

@allowed([
  'Disabled'
  'Enabled'
])
@description('The public network access setting on the AVD workspace either disables public network access or allows both public and private network access.')
param workspacePublicNetworkAccess string = 'Enabled'

// OTHER LOGIC & COMPUTED VALUES
var avdStorageAccountEndpoint = '${avdStorageAccountName}.blob.${environment().suffixes.storage}'
var avdStorageAccountName = startsWith(location, 'usn') ? 'wvdexportalcontainer' : 'wvdportalstorageblob'
var privateDnsZoneResourceIdPrefix = '/subscriptions/${split(hubVirtualNetworkResourceId, '/')[2]}/resourceGroups/${split(hubVirtualNetworkResourceId, '/')[4]}/providers/Microsoft.Network/privateDnsZones/'
var subscriptionId = subscription().subscriptionId

// Optionally deploys telemetry for ArcGIS Pro deployments
#disable-next-line no-deployments-resources
resource partnerTelemetry 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'pid-4e82be1d-7fcb-4913-a90c-aa84d7ea3a1c'
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

// Deploys the tier3 resources to support AVD
module tier3 '../../tier3/solution.bicep' = {
  name: 'deploy-tier3-avd-stamp-${deploymentNameSuffix}'
  params: {
    additionalSubnets: [
      {
        name: 'avd-management'
        properties: {
          addressPrefix: managementSubnetAddressPrefix
        }
      }
    ]
    customFirewallRuleCollectionGroups: []
    deployActivityLogDiagnosticSetting: deployActivityLogDiagnosticSetting
    deployDefender: deployDefender
    deployNetworkWatcherTrafficAnalytics: deployNetworkWatcherTrafficAnalytics
    deployPolicy: deployPolicy
    emailSecurityContact: emailSecurityContact
    environmentAbbreviation: environmentAbbreviation
    firewallResourceId: hubAzureFirewallResourceId
    hubStorageAccountResourceId: hubStorageAccountResourceId
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
    identifier: identifier
    location: location
    logAnalyticsWorkspaceResourceId: operationsLogAnalyticsWorkspaceResourceId
    logStorageSkuName: logStorageSkuName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkWatcherFlowLogsRetentionDays: networkWatcherFlowLogsRetentionDays
    networkWatcherFlowLogsType: networkWatcherFlowLogsType
    policy: policy
    subnetAddressPrefix: sessionHostsSubnetAddressPrefix
    subnetName: 'avd-session-hosts'
    tags: tags
    virtualNetworkAddressPrefix: stampVirtualNetworkAddressPrefix
    windowsAdministratorsGroupMembership: virtualMachineAdminUsername
    workloadName: 'avd'
    workloadShortName: 'avd'
  }
}

var resourceGroupName = replace(
  tier3.outputs.tier.namingConvention.resourceGroup,
  tier3.outputs.tokens.purpose,
  'stamp'
)

module rg '../../../modules/resource-group.bicep' = {
  name: 'deploy-rg-${deploymentNameSuffix}'
  params: {
    location: location
    name: resourceGroupName
    tags: union(
      {
        'cm-resource-parent': resourceId(
          subscription().subscriptionId,
          resourceGroupName,
          'Microsoft.DesktopVirtualization/hostpools',
          replace(
            tier3.outputs.tier.namingConvention.hostPool,
            '${tier3.outputs.delimiter}${tier3.outputs.tokens.purpose}',
            ''
          )
        )
      },
      tags[?'Microsoft.Resources/resourceGroups'] ?? {},
      tier3.outputs.mlzTags
    )
  }
}

// Deploys the management resource group and resources
module management 'management/management.bicep' = {
  name: 'deploy-management-${deploymentNameSuffix}'
  params: {
    avdObjectId: avdObjectId
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    location: location
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupName: rg.outputs.name
    subscriptionId: subscriptionId
    tags: tags
    tier: tier3.outputs.tier
    delimiter: tier3.outputs.delimiter
    tokens: tier3.outputs.tokens
    mlzTags: tier3.outputs.mlzTags
    namingConvention: tier3.outputs.tier.namingConvention
    privateDnsZones: tier3.outputs.privateDnsZones
    resourceAbbreviations: tier3.outputs.resourceAbbreviations
  }
}

module controlPlane 'control-plane/control-plane.bicep' = {
  name: 'deploy-control-plane-${deploymentNameSuffix}'
  params: {
    avdPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(tier3.outputs.privateDnsZones, name => startsWith(name, 'privatelink.wvd'))[0]}'
    delimiter: tier3.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    location: location
    logAnalyticsWorkspaceResourceId: management.outputs.logAnalyticsWorkspaceResourceId
    mlzTags: tier3.outputs.mlzTags
    resourceGroupName: rg.outputs.name
    securityPrincipalObjectId: map(securityPrincipals, item => item.objectId)[0]
    tags: tags
    tier: tier3.outputs.tier
    tokens: tier3.outputs.tokens
    vmTemplate: '{"domain":"${domainName}","galleryImageOffer":"pro-byol","galleryImagePublisher":"esri","galleryImageSKU":"pro-byol-36","imageType":"Gallery","customImageId":null,"namePrefix":"${replace(tier3.outputs.tier.namingConvention.virtualMachine, '${tier3.outputs.delimiter}${tier3.outputs.tokens.purpose}', '')}","osDiskType":"Premium_LRS","vmSize":{"id":"${virtualMachineSize}","cores":null,"ram":null,"rdmaEnabled": false,"supportsMemoryPreservingMaintenance": true},"galleryItemId":"esri.pro-byol.pro-byol-36","hibernate":false,"diskSizeGB":0,"securityType":"TrustedLaunch","secureBoot":true,"vTPM":true,"vmInfrastructureType":"Cloud","virtualProcessorCount":null,"memoryGB":null,"maximumMemoryGB":null,"minimumMemoryGB":null,"dynamicMemoryConfig":false}'
    workspaceGlobalPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(tier3.outputs.privateDnsZones, name => startsWith(name, 'privatelink-global.wvd'))[0]}'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

// Deploys the resource group and resources for the AVD session hosts
module sessionHosts 'session-hosts/session-hosts.bicep' = {
  name: 'deploy-session-hosts-${deploymentNameSuffix}'
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdConfigurationZipFileUri: 'https://${avdStorageAccountEndpoint}/galleryartifacts/Configuration_1.0.03211.1002.zip'
    dataCollectionRuleResourceId: management.outputs.dataCollectionRuleResourceId
    delimiter: tier3.outputs.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    diskAccessPolicyDefinitionId: management.outputs.diskAccessPolicyDefinitionId
    diskAccessPolicyDisplayName: management.outputs.diskAccessPolicyDisplayName
    diskAccessResourceId: management.outputs.diskAccessResourceId
    diskEncryptionSetResourceId: management.outputs.diskEncryptionSetResourceId
    fileShare: fileShare
    hostPoolResourceId: controlPlane.outputs.hostPoolResourceId
    location: location
    mlzTags: tier3.outputs.mlzTags
    resourceGroupName: resourceGroupName
    securityPrincipalObjectId: map(securityPrincipals, item => item.objectId)[0]
    tags: tags
    tier: tier3.outputs.tier
    tokens: tier3.outputs.tokens
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineSize: virtualMachineSize
  }
}
