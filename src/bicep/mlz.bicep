targetScope = 'subscription'

/*

  NAMING CONVENTIONS

  Here we define some naming conventions for resources.

  First, take `resourcePrefix` and `resourceSuffix` by params.
  Then, we use string interpolation to insert those values into a naming convention.
  
  We were inspired for these abbreviations by: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
  We were inspired for these naming conventions by: https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

*/

var namingConvention = '${resourcePrefix}-resource_token-mlz_token-${resourceSuffix}'

var bastionHostNamingConvention = replace(namingConvention, 'resource_token', 'bas')
var firewallNamingConvention = replace(namingConvention, 'resource_token', 'afw')
var firewallPolicyNamingConvention = replace(namingConvention, 'resource_token', 'afwp')
var ipConfigurationNamingConvention = replace(namingConvention, 'resource_token', 'ipconf')
var logAnalyticsWorkspaceNamingConvention = replace(namingConvention, 'resource_token', 'log')
var networkInterfaceNamingConvention = replace(namingConvention, 'resource_token', 'nic')
var networkSecurityGroupNamingConvention = replace(namingConvention, 'resource_token', 'nsg')
var publicIpAddressNamingConvention = replace(namingConvention, 'resource_token', 'pip')
var resourceGroupNamingConvention = replace(namingConvention, 'resource_token', 'rg')
var storageAccountNamingConvention = '${resourcePrefix}stmlz_token${uniqueString(resourcePrefix, guid(nowUtc))}' // we use unique string here to generate uniqueness
var subnetNamingConvention = replace(namingConvention, 'resource_token', 'subnet')
var virtualMachineNamingConvention = replace(namingConvention, 'resource_token', 'vm')
var virtualNetworkNamingConvention = replace(namingConvention, 'resource_token', 'vnet')

/*

  CALCULATED VALUES

  Here, we reference the naming conventions described above.
  Then, use the replace() function to insert unique resource types and values into the naming convention.

*/

// HUB NAMES

var hubResourceGroupName =  replace(resourceGroupNamingConvention, 'mlz_token', 'hub')
var hubLogStorageAccountName = replace(storageAccountNamingConvention, 'mlz_token', 'hub')
var hubVirtualNetworkName = replace(virtualNetworkNamingConvention, 'mlz_token', 'hub')
var hubNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, 'mlz_token', 'hub')
var hubSubnetName = replace(subnetNamingConvention, 'mlz_token', 'hub')

// IDENTITY NAMES

var identityResourceGroupName = replace(resourceGroupNamingConvention, 'mlz_token', 'identity')
var identityLogStorageAccountName = replace(storageAccountNamingConvention, 'mlz_token', 'id')
var identityVirtualNetworkName = replace(virtualNetworkNamingConvention, 'mlz_token', 'identity')
var identityNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, 'mlz_token', 'identity')
var identitySubnetName = replace(subnetNamingConvention, 'mlz_token', 'identity')

// OPERATIONS NAMES

var operationsResourceGroupName = replace(resourceGroupNamingConvention, 'mlz_token', 'operations')
var operationsLogStorageAccountName = replace(storageAccountNamingConvention, 'mlz_token', 'ops')
var operationsVirtualNetworkName = replace(virtualNetworkNamingConvention, 'mlz_token', 'operations')
var operationsNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, 'mlz_token', 'operations')
var operationsSubnetName = replace(subnetNamingConvention, 'mlz_token', 'operations')

// SHARED SERVICES NAMES

var sharedServicesResourceGroupName = replace(resourceGroupNamingConvention, 'mlz_token', 'sharedServices')
var sharedServicesLogStorageAccountName = replace(storageAccountNamingConvention, 'mlz_token', 'svcs')
var sharedServicesVirtualNetworkName = replace(virtualNetworkNamingConvention, 'mlz_token', 'sharedServices')
var sharedServicesNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, 'mlz_token', 'sharedServices')
var sharedServicesSubnetName = replace(subnetNamingConvention, 'mlz_token', 'sharedServices')

// LOG ANALYTICS NAMES

var logAnalyticsWorkspaceName = replace(logAnalyticsWorkspaceNamingConvention, 'mlz_token', 'operations')

// FIREWALL NAMES

var firewallName = replace(firewallNamingConvention, 'mlz_token', 'hub')
var firewallPolicyName = replace(firewallPolicyNamingConvention, 'mlz_token', 'hub')
var firewallClientIpConfigurationName = replace(firewallManagementIpConfigurationName, 'mlz_token', 'hub')
var firewallClientPublicIPAddressName = replace(publicIpAddressNamingConvention, 'mlz_token', 'afw-client')
var firewallManagementPublicIPAddressName = replace(publicIpAddressNamingConvention, 'mlz_token', 'afw-mgmt')

// BASTION NAMES

var bastionHostName = replace(bastionHostNamingConvention, 'mlz_token', 'hub')
var bastionHostPublicIPAddressName = replace(publicIpAddressNamingConvention, 'mlz_token', 'bas')
var bastionHostIPConfigurationName = replace(ipConfigurationNamingConvention, 'mlz_token', 'bas')
var linuxNetworkInterfaceName = replace(networkInterfaceNamingConvention, 'mlz_token', 'bas-linux')
var linuxNetworkInterfaceIpConfigurationName = replace(ipConfigurationNamingConvention, 'mlz_token', 'bas-linux')
var linuxVmName = replace(virtualMachineNamingConvention, 'mlz_token', 'bas-linux')
var windowsNetworkInterfaceName = replace(networkInterfaceNamingConvention, 'mlz_token', 'bas-windows')
var windowsNetworkInterfaceIpConfigurationName = replace(ipConfigurationNamingConvention, 'mlz_token', 'bas-windows')
var windowsVmName = replace(virtualMachineNamingConvention, 'mlz_token', 'bas-windows')

// SPOKES

var spokes = [
  {
    name: 'identity'
    subscriptionId: identitySubscriptionId
    resourceGroupName: identityResourceGroupName
    logStorageAccountName: identityLogStorageAccountName
    virtualNetworkName: identityVirtualNetworkName
    virtualNetworkAddressPrefix: identityVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: identityVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: identityVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: identityNetworkSecurityGroupName
    networkSecurityGroupRules: identityNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: identityNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: identityNetworkSecurityGroupDiagnosticsMetrics
    subnetName: identitySubnetName
    subnetAddressPrefix: identitySubnetAddressPrefix
    subnetServiceEndpoints: identitySubnetServiceEndpoints
  }
  {
    name: 'operations'
    subscriptionId: operationsSubscriptionId
    resourceGroupName: operationsResourceGroupName
    logStorageAccountName: operationsLogStorageAccountName
    virtualNetworkName: operationsVirtualNetworkName
    virtualNetworkAddressPrefix: operationsVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: operationsVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: operationsVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: operationsNetworkSecurityGroupName
    networkSecurityGroupRules: operationsNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: operationsNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: operationsNetworkSecurityGroupDiagnosticsMetrics
    subnetName: operationsSubnetName
    subnetAddressPrefix: operationsSubnetAddressPrefix
    subnetServiceEndpoints: operationsSubnetServiceEndpoints
  }
  {
    name: 'sharedServices'
    subscriptionId: sharedServicesSubscriptionId
    resourceGroupName: sharedServicesResourceGroupName
    logStorageAccountName: sharedServicesLogStorageAccountName
    virtualNetworkName: sharedServicesVirtualNetworkName
    virtualNetworkAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics
    networkSecurityGroupName: sharedServicesNetworkSecurityGroupName
    networkSecurityGroupRules: sharedServicesNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: sharedServicesNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: sharedServicesNetworkSecurityGroupDiagnosticsMetrics
    subnetName: sharedServicesSubnetName
    subnetAddressPrefix: sharedServicesSubnetAddressPrefix
    subnetServiceEndpoints: sharedServicesSubnetServiceEndpoints
  }
]

/*

  RESOURCES

  Here, we create deployable resources.

*/

// RESOURCE GROUPS

module hubResourceGroup './modules/resourceGroup.bicep' = {
  name: 'deploy-rg-hub-${nowUtc}'
  scope: subscription(hubSubscriptionId)
  params: {
    name: hubResourceGroupName
    location: location
    tags: calculatedTags
  }
}

module spokeResourceGroups './modules/resourceGroup.bicep' = [for spoke in spokes: {
  name: 'deploy-rg-${spoke.name}-${nowUtc}'
  scope: subscription(spoke.subscriptionId)
  params: {
    name: spoke.resourceGroupName
    location: spoke.location
    tags: calculatedTags
  }
}]

// LOG ANALYTICS WORKSPACE

module logAnalyticsWorkspace './modules/logAnalyticsWorkspace.bicep' = {
  name: 'deploy-laws-${nowUtc}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: calculatedTags
    deploySentinel: deploySentinel
    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
  dependsOn: [
    spokeResourceGroups
  ]
}

// HUB AND SPOKE NETWORKS

module hubNetwork './modules/hubNetwork.bicep' = {
  name: 'deploy-vnet-hub-${nowUtc}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    location: location
    tags: calculatedTags

    logStorageAccountName: hubLogStorageAccountName
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    virtualNetworkName: hubVirtualNetworkName
    virtualNetworkAddressPrefix: hubVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: hubVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: hubVirtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: hubNetworkSecurityGroupName
    networkSecurityGroupRules: hubNetworkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: hubNetworkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: hubNetworkSecurityGroupDiagnosticsMetrics

    subnetName: hubSubnetName
    subnetAddressPrefix: hubSubnetAddressPrefix
    subnetServiceEndpoints: hubSubnetServiceEndpoints

    firewallName: firewallName
    firewallSkuTier: firewallSkuTier
    firewallPolicyName: firewallPolicyName
    firewallThreatIntelMode: firewallThreatIntelMode
    firewallIntrusionDetectionMode: firewallIntrusionDetectionMode
    firewallDiagnosticsLogs: firewallDiagnosticsLogs
    firewallDiagnosticsMetrics: firewallDiagnosticsMetrics
    firewallClientIpConfigurationName: firewallClientIpConfigurationName
    firewallClientSubnetName: 'AzureFirewallSubnet' // must be 'AzureFirewallSubnet'
    firewallClientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
    firewallClientSubnetServiceEndpoints: firewallClientSubnetServiceEndpoints
    firewallClientPublicIPAddressName: firewallClientPublicIPAddressName
    firewallClientPublicIPAddressSkuName: firewallClientPublicIPAddressSkuName
    firewallClientPublicIpAllocationMethod: firewallClientPublicIpAllocationMethod
    firewallClientPublicIPAddressAvailabilityZones: firewallClientPublicIPAddressAvailabilityZones
    firewallManagementIpConfigurationName: firewallManagementIpConfigurationName
    firewallManagementSubnetName: 'AzureFirewallManagementSubnet' //this must be 'AzureFirewallManagementSubnet'
    firewallManagementSubnetAddressPrefix: firewallManagementSubnetAddressPrefix
    firewallManagementSubnetServiceEndpoints: firewallManagementSubnetServiceEndpoints
    firewallManagementPublicIPAddressName: firewallManagementPublicIPAddressName
    firewallManagementPublicIPAddressSkuName: firewallManagementPublicIPAddressSkuName
    firewallManagementPublicIpAllocationMethod: firewallManagementPublicIpAllocationMethod
    firewallManagementPublicIPAddressAvailabilityZones: firewallManagementPublicIPAddressAvailabilityZones

    publicIPAddressDiagnosticsLogs: publicIPAddressDiagnosticsLogs
    publicIPAddressDiagnosticsMetrics: publicIPAddressDiagnosticsMetrics
  }
}

module spokeNetworks './modules/spokeNetwork.bicep' = [ for spoke in spokes: {
  name: 'deploy-vnet-${spoke.name}-${nowUtc}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    location: spoke.location
    tags: calculatedTags

    logStorageAccountName: string(take(spoke.logStorageAccountName, 24))
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    firewallPrivateIPAddress: hubNetwork.outputs.firewallPrivateIPAddress

    virtualNetworkName: spoke.virtualNetworkName
    virtualNetworkAddressPrefix: spoke.virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: spoke.virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: spoke.virtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: spoke.networkSecurityGroupName
    networkSecurityGroupRules: spoke.networkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: spoke.networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: spoke.networkSecurityGroupDiagnosticsMetrics

    subnetName: spoke.subnetName
    subnetAddressPrefix: spoke.subnetAddressPrefix
    subnetServiceEndpoints: spoke.subnetServiceEndpoints
  }
}]

// VIRTUAL NETWORK PEERINGS

module hubVirtualNetworkPeerings './modules/hubNetworkPeerings.bicep' = {
  name: 'deploy-vnet-peerings-hub-${nowUtc}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    spokes: [ for (spoke, i) in spokes: {
      type: spoke.name
      virtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
      virtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
    }]
  }
}

module spokeVirtualNetworkPeerings './modules/spokeNetworkPeering.bicep' = [ for (spoke, i) in spokes: {
  name: 'deploy-vnet-peerings-${spoke.name}-${nowUtc}'
  scope: subscription(spoke.subscriptionId)
  params: {
    spokeName: spoke.name
    spokeResourceGroupName: spoke.resourceGroupName
    spokeVirtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubVirtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
  }
}]

// POLICY ASSIGNMENTS

module hubPolicyAssignment './modules/policyAssignment.bicep' = if(deployPolicy) {
  name: 'assign-policy-hub-${nowUtc}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspace.outputs.resourceGroupName
    operationsSubscriptionId: operationsSubscriptionId
  }
}

module spokePolicyAssignments './modules/policyAssignment.bicep' = [ for spoke in spokes: if(deployPolicy) {
  name: 'assign-policy-${spoke.name}-${nowUtc}'
  scope: resourceGroup(spoke.subscriptionId, spoke.resourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspace.outputs.resourceGroupName
    operationsSubscriptionId: operationsSubscriptionId
  }
}]

// CENTRAL LOGGING

module hubSubscriptionActivityLogging './modules/centralLogging.bicep' = {
  name: 'activity-logs-hub-${nowUtc}'
  scope: subscription(hubSubscriptionId)
  params: {
    diagnosticSettingName: 'log-hub-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
  dependsOn: [
    hubNetwork
  ]
}

module spokeSubscriptionActivityLogging './modules/centralLogging.bicep' = [ for spoke in spokes: if(spoke.subscriptionId != hubSubscriptionId) {
  name: 'activity-logs-${spoke.name}-${nowUtc}'
  scope: subscription(spoke.subscriptionId)
  params: {
    diagnosticSettingName: 'log-${spoke.name}-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
  dependsOn: [
    spokeNetworks
  ]
}]

module logAnalyticsDiagnosticLogging './modules/logAnalyticsDiagnosticLogging.bicep' = {
  name: 'deploy-diagnostic-logging-LAWS'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    diagnosticStorageAccountName: operationsLogStorageAccountName
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
  dependsOn: [
    hubNetwork
    spokeNetworks
  ]
}

// SECURITY CENTER

module hubSecurityCenter './modules/securityCenter.bicep' = if(deployASC) {
  name: 'set-hub-sub-security-center'
  scope: subscription(hubSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    emailSecurityContact: emailSecurityContact
  }
}

module spokeSecurityCenter './modules/securityCenter.bicep' = [ for spoke in spokes: if( (deployASC) && (spoke.subscriptionId != hubSubscriptionId) ) {
  name: 'set-${spoke.name}-sub-security-center'
  scope: subscription(operationsSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
    emailSecurityContact: emailSecurityContact
  }
}]

// REMOTE ACCESS

module remoteAccess './modules/remoteAccess.bicep' = if(deployRemoteAccess) {
  name: 'deploy-remote-access-${nowUtc}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)

  params: {
    location: location

    hubVirtualNetworkName: hubNetwork.outputs.virtualNetworkName
    hubSubnetResourceId: hubNetwork.outputs.subnetResourceId
    hubNetworkSecurityGroupResourceId: hubNetwork.outputs.networkSecurityGroupResourceId

    bastionHostName: bastionHostName
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    bastionHostPublicIPAddressName: bastionHostPublicIPAddressName
    bastionHostPublicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    bastionHostPublicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    bastionHostPublicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    bastionHostIPConfigurationName: bastionHostIPConfigurationName

    linuxNetworkInterfaceName: linuxNetworkInterfaceName
    linuxNetworkInterfaceIpConfigurationName: linuxNetworkInterfaceIpConfigurationName
    linuxNetworkInterfacePrivateIPAddressAllocationMethod: linuxNetworkInterfacePrivateIPAddressAllocationMethod

    linuxVmName: linuxVmName
    linuxVmSize: linuxVmSize
    linuxVmOsDiskCreateOption: linuxVmOsDiskCreateOption
    linuxVmOsDiskType: linuxVmOsDiskType
    linuxVmImagePublisher: linuxVmImagePublisher
    linuxVmImageOffer: linuxVmImageOffer
    linuxVmImageSku: linuxVmImageSku
    linuxVmImageVersion: linuxVmImageVersion
    linuxVmAdminUsername: linuxVmAdminUsername
    linuxVmAuthenticationType: linuxVmAuthenticationType
    linuxVmAdminPasswordOrKey: linuxVmAdminPasswordOrKey

    windowsNetworkInterfaceName: windowsNetworkInterfaceName
    windowsNetworkInterfaceIpConfigurationName: windowsNetworkInterfaceIpConfigurationName
    windowsNetworkInterfacePrivateIPAddressAllocationMethod: windowsNetworkInterfacePrivateIPAddressAllocationMethod

    windowsVmName: windowsVmName
    windowsVmSize: windowsVmSize
    windowsVmAdminUsername: windowsVmAdminUsername
    windowsVmAdminPassword: windowsVmAdminPassword
    windowsVmPublisher: windowsVmPublisher
    windowsVmOffer: windowsVmOffer
    windowsVmSku: windowsVmSku
    windowsVmVersion: windowsVmVersion
    windowsVmCreateOption: windowsVmCreateOption
    windowsVmStorageAccountType: windowsVmStorageAccountType

    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

/*

  PARAMETERS

  Here are all the parameters a user can override.

  These are the mandatory parameters that Mission LZ does not provide a default for:
    - resourcePrefix

*/

@minLength(3)
@maxLength(10)
@description('A prefix, 3-10 alphanumeric characters without whitespace, used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string

@minLength(3)
@maxLength(6)
@description('A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz")')
param resourceSuffix string = 'mlz'

@description('The region to deploy resources into')
param location string = deployment().location

@description('The Storage Account SKU to use for log storage')
param logStorageSkuName string = 'Standard_GRS'


param hubSubscriptionId string = subscription().subscriptionId
param identitySubscriptionId string = hubSubscriptionId
param operationsSubscriptionId string = hubSubscriptionId
param sharedServicesSubscriptionId string = hubSubscriptionId

@allowed([
  'Standard'
  'Premium'
])
param firewallSkuTier string = 'Premium'

param hubVirtualNetworkAddressPrefix string = '10.0.100.0/24'
param hubSubnetAddressPrefix string = '10.0.100.128/27'
param hubVirtualNetworkDiagnosticsLogs array = []
param hubVirtualNetworkDiagnosticsMetrics array = []
param hubNetworkSecurityGroupRules array = []
param hubNetworkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]
param hubNetworkSecurityGroupDiagnosticsMetrics array = []
param hubSubnetServiceEndpoints array = [
  {
    service: 'Microsoft.Storage'
  }
]

param firewallManagementSubnetAddressPrefix string = '10.0.100.64/26'
param firewallClientSubnetAddressPrefix string = '10.0.100.0/26'

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallThreatIntelMode string = 'Alert'

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param firewallIntrusionDetectionMode string = 'Alert'

param firewallDiagnosticsLogs array = [
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
]
param firewallDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

param firewallClientSubnetServiceEndpoints array = []
param firewallClientPublicIPAddressSkuName string = 'Standard'
param firewallClientPublicIpAllocationMethod string = 'Static'
param firewallClientPublicIPAddressAvailabilityZones array = []
param firewallManagementIpConfigurationName string = 'firewall-management-ip-config'
param firewallManagementSubnetServiceEndpoints array = []
param firewallManagementPublicIPAddressSkuName string = 'Standard'
param firewallManagementPublicIpAllocationMethod string = 'Static'
param firewallManagementPublicIPAddressAvailabilityZones array = []
param publicIPAddressDiagnosticsLogs array = [
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
param publicIPAddressDiagnosticsMetrics array = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]

param identityVirtualNetworkAddressPrefix string = '10.0.110.0/26'
param identityVirtualNetworkDiagnosticsLogs array = hubVirtualNetworkDiagnosticsLogs
param identityVirtualNetworkDiagnosticsMetrics array = hubVirtualNetworkDiagnosticsMetrics
param identityNetworkSecurityGroupRules array = hubNetworkSecurityGroupRules
param identityNetworkSecurityGroupDiagnosticsLogs array = hubNetworkSecurityGroupDiagnosticsLogs
param identityNetworkSecurityGroupDiagnosticsMetrics array = hubNetworkSecurityGroupDiagnosticsMetrics
param identitySubnetAddressPrefix string = '10.0.110.0/27'
param identitySubnetServiceEndpoints array = hubSubnetServiceEndpoints

param operationsVirtualNetworkAddressPrefix string = '10.0.115.0/26'
param operationsVirtualNetworkDiagnosticsLogs array = hubVirtualNetworkDiagnosticsLogs
param operationsVirtualNetworkDiagnosticsMetrics array = hubVirtualNetworkDiagnosticsMetrics
param operationsNetworkSecurityGroupRules array = hubNetworkSecurityGroupRules
param operationsNetworkSecurityGroupDiagnosticsLogs array = hubNetworkSecurityGroupDiagnosticsLogs
param operationsNetworkSecurityGroupDiagnosticsMetrics array = hubNetworkSecurityGroupDiagnosticsMetrics
param operationsSubnetAddressPrefix string = '10.0.115.0/27'
param operationsSubnetServiceEndpoints array = hubSubnetServiceEndpoints

param sharedServicesVirtualNetworkAddressPrefix string = '10.0.120.0/26'
param sharedServicesVirtualNetworkDiagnosticsLogs array = hubVirtualNetworkDiagnosticsLogs
param sharedServicesVirtualNetworkDiagnosticsMetrics array = hubVirtualNetworkDiagnosticsMetrics
param sharedServicesNetworkSecurityGroupRules array = hubNetworkSecurityGroupRules
param sharedServicesNetworkSecurityGroupDiagnosticsLogs array = hubNetworkSecurityGroupDiagnosticsLogs
param sharedServicesNetworkSecurityGroupDiagnosticsMetrics array = hubNetworkSecurityGroupDiagnosticsMetrics
param sharedServicesSubnetAddressPrefix string = '10.0.120.0/27'
param sharedServicesSubnetServiceEndpoints array = hubSubnetServiceEndpoints

param logAnalyticsWorkspaceCappingDailyQuotaGb int = -1
param logAnalyticsWorkspaceRetentionInDays int = 30
param logAnalyticsWorkspaceSkuName string = 'PerGB2018'

@description('When set to "True", enables Microsoft Sentinel within the MLZ Log Analytics workspace.')
param deploySentinel bool = false

@allowed([
  'NIST'
  'IL5' // AzureUsGoverment only, trying to deploy IL5 in AzureCloud will switch to NIST
  'CMMC'
])
@description('[NIST/IL5/CMMC] Built-in policy assignments to assign, default is NIST. IL5 is only available for AzureUsGovernment and will switch to NIST if tried in AzureCloud.')
param policy string = 'NIST'
param deployPolicy bool = false

@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string = ''
param deployASC bool = false

@description('Provision Azure Bastion Host and jumpboxes in this deployment')
param deployRemoteAccess bool = false
param bastionHostSubnetAddressPrefix string = '10.0.100.160/27'
param bastionHostPublicIPAddressSkuName string = 'Standard'
param bastionHostPublicIPAddressAllocationMethod string = 'Static'
param bastionHostPublicIPAddressAvailabilityZones array = []
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'
param linuxVmSize string = 'Standard_B2s'
param linuxVmOsDiskCreateOption string = 'FromImage'
param linuxVmOsDiskType string = 'Standard_LRS'
param linuxVmImagePublisher string = 'Canonical'
param linuxVmImageOffer string = 'UbuntuServer'
param linuxVmImageSku string = '18.04-LTS'
param linuxVmImageVersion string = 'latest'
param linuxVmAdminUsername string = 'azureuser'
@allowed([
  'sshPublicKey'
  'password'
])
param linuxVmAuthenticationType string = 'password'
@secure()
@minLength(14)
param linuxVmAdminPasswordOrKey string = deployRemoteAccess ? '' : newGuid()
param windowsNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'
param windowsVmSize string = 'Standard_DS1_v2'
param windowsVmAdminUsername string = 'azureuser'
@secure()
@minLength(14)
param windowsVmAdminPassword string = deployRemoteAccess ? '' : newGuid()
param windowsVmPublisher string = 'MicrosoftWindowsServer'
param windowsVmOffer string = 'WindowsServer'
param windowsVmSku string = '2019-datacenter'
param windowsVmVersion string = 'latest'
param windowsVmCreateOption string = 'FromImage'
param windowsVmStorageAccountType string = 'StandardSSD_LRS'

param tags object = {}
var defaultTags = {
  'resourcePrefix': resourcePrefix
  'DeploymentType': 'MissionLandingZoneARM'
}
var calculatedTags = union(tags,defaultTags)

param nowUtc string = utcNow()

/*

  OUTPUTS

  Here, we emit objects to be used post-deployment.
  
  A user can reference these outputs with the `az deployment sub show` command like this:

    az deployment sub show --name <your deployment name> --query properties.outputs

  With that output as JSON you could pass it as arguments to another deployment using the Shared Variable File Pattern:
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file
  
  The output is a JSON object, you can use your favorite tool, like PowerShell or jq, to parse the values you need.

*/

output mlzResourcePrefix string = resourcePrefix

output firewallPrivateIPAddress string = hubNetwork.outputs.firewallPrivateIPAddress

output hub object = {
  subscriptionId: hubSubscriptionId
  resourceGroupName: hubResourceGroup.outputs.name
  resourceGroupResourceId: hubResourceGroup.outputs.id
  virtualNetworkName: hubNetwork.outputs.virtualNetworkName
  virtualNetworkResourceId: hubNetwork.outputs.virtualNetworkResourceId
  subnetName: hubNetwork.outputs.subnetName
  subnetResourceId: hubNetwork.outputs.subnetResourceId
  subnetAddressPrefix: hubNetwork.outputs.subnetAddressPrefix
  networkSecurityGroupName: hubNetwork.outputs.networkSecurityGroupName
  networkSecurityGroupResourceId: hubNetwork.outputs.networkSecurityGroupResourceId
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.id

output spokes array = [for (spoke, i) in spokes: {
  name: spoke.name
  subscriptionId: spoke.subscriptionId
  resourceGroupName: spokeResourceGroups[i].outputs.name
  resourceGroupId: spokeResourceGroups[i].outputs.id
  virtualNetworkName: spokeNetworks[i].outputs.virtualNetworkName
  virtualNetworkResourceId: spokeNetworks[i].outputs.virtualNetworkResourceId
  subnetName: spokeNetworks[i].outputs.subnetName
  subnetResourceId: spokeNetworks[i].outputs.subnetResourceId
  subnetAddressPrefix: spokeNetworks[i].outputs.subnetAddressPrefix
  networkSecurityGroupName: spokeNetworks[i].outputs.networkSecurityGroupName
  networkSecurityGroupResourceId: spokeNetworks[i].outputs.networkSecurityGroupResourceId
}]
