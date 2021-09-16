// scope
targetScope = 'subscription'

// main

//// scaffolding

module hubResourceGroup './modules/resourceGroup.bicep' = {
  name: 'deploy-hub-rg-${nowUtc}'
  scope: subscription(hubSubscriptionId)
  params: {
    name: hubResourceGroupName
    location: hubLocation
    tags: tags
  }
}

module identityResourceGroup './modules/resourceGroup.bicep' = {
  name: 'deploy-identity-rg-${nowUtc}'
  scope: subscription(identitySubscriptionId)
  params: {
    name: identityResourceGroupName
    location: identityLocation
    tags: tags
  }
}

module operationsResourceGroup './modules/resourceGroup.bicep' = {
  name: 'deploy-operations-rg-${nowUtc}'
  scope: subscription(operationsSubscriptionId)
  params: {
    name: operationsResourceGroupName
    location: operationsLocation
    tags: tags
  }
}

module sharedServicesResourceGroup './modules/resourceGroup.bicep' = {
  name: 'deploy-sharedServices-rg-${nowUtc}'
  scope: subscription(sharedServicesSubscriptionId)
  params: {
    name: sharedServicesResourceGroupName
    location: sharedServicesLocation
    tags: tags
  }
}

//// logging

module logAnalyticsWorkspace './modules/logAnalyticsWorkspace.bicep' = {
  name: 'deploy-laws-${nowUtc}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    name: logAnalyticsWorkspaceName
    location: logAnalyticsWorkspaceLocation
    tags: tags

    retentionInDays: logAnalyticsWorkspaceRetentionInDays
    skuName: logAnalyticsWorkspaceSkuName
    workspaceCappingDailyQuotaGb: logAnalyticsWorkspaceCappingDailyQuotaGb
  }
  dependsOn: [
    operationsResourceGroup
  ]
}

//// hub and spoke

module hub './modules/hubNetwork.bicep' = {
  name: 'deploy-hub-${nowUtc}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    location: hubLocation
    tags: tags

    logStorageAccountName: hubLogStorageAccountName
    logStorageSkuName: hubLogStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    virtualNetworkName: hubVirtualNetworkName
    virtualNetworkAddressPrefix: hubVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: hubVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: hubVirtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: hubNetworkSecurityGroupName
    networkSecurityGroupRules: hubNetworkSecurityGroupRules

    subnetName: hubSubnetName
    subnetAddressPrefix: hubSubnetAddressPrefix
    subnetServiceEndpoints: hubSubnetServiceEndpoints

    firewallName: firewallName
    firewallSkuTier: firewallSkuTier
    firewallPolicyName: firewallPolicyName
    firewallThreatIntelMode: firewallThreatIntelMode
    firewallClientIpConfigurationName: firewallClientIpConfigurationName
    firewallClientSubnetName: firewallClientSubnetName
    firewallClientSubnetAddressPrefix: firewallClientSubnetAddressPrefix
    firewallClientSubnetServiceEndpoints: firewallClientSubnetServiceEndpoints
    firewallClientPublicIPAddressName: firewallClientPublicIPAddressName
    firewallClientPublicIPAddressSkuName: firewallClientPublicIPAddressSkuName
    firewallClientPublicIpAllocationMethod: firewallClientPublicIpAllocationMethod
    firewallClientPublicIPAddressAvailabilityZones: firewallClientPublicIPAddressAvailabilityZones
    firewallManagementIpConfigurationName: firewallManagementIpConfigurationName
    firewallManagementSubnetName: firewallManagementSubnetName
    firewallManagementSubnetAddressPrefix: firewallManagementSubnetAddressPrefix
    firewallManagementSubnetServiceEndpoints: firewallManagementSubnetServiceEndpoints
    firewallManagementPublicIPAddressName: firewallManagementPublicIPAddressName
    firewallManagementPublicIPAddressSkuName: firewallManagementPublicIPAddressSkuName
    firewallManagementPublicIpAllocationMethod: firewallManagementPublicIpAllocationMethod
    firewallManagementPublicIPAddressAvailabilityZones: firewallManagementPublicIPAddressAvailabilityZones
  }
}

module identity './modules/spokeNetwork.bicep' = {
  name: 'deploy-identity-spoke-${nowUtc}'
  scope: resourceGroup(identitySubscriptionId, identityResourceGroupName)
  params: {
    location: identityLocation
    tags: tags

    logStorageAccountName: identityLogStorageAccountName
    logStorageSkuName: identityLogStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    firewallPrivateIPAddress: hub.outputs.firewallPrivateIPAddress

    virtualNetworkName: identityVirtualNetworkName
    virtualNetworkAddressPrefix: identityVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: identityVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: identityVirtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: identityNetworkSecurityGroupName
    networkSecurityGroupRules: identityNetworkSecurityGroupRules

    subnetName: identitySubnetName
    subnetAddressPrefix: identitySubnetAddressPrefix
    subnetServiceEndpoints: identitySubnetServiceEndpoints
  }
}

module operations './modules/spokeNetwork.bicep' = {
  name: 'deploy-operations-spoke-${nowUtc}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    location: operationsLocation
    tags: tags

    logStorageAccountName: operationsLogStorageAccountName
    logStorageSkuName: operationsLogStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    firewallPrivateIPAddress: hub.outputs.firewallPrivateIPAddress

    virtualNetworkName: operationsVirtualNetworkName
    virtualNetworkAddressPrefix: operationsVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: operationsVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: operationsVirtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: operationsNetworkSecurityGroupName
    networkSecurityGroupRules: operationsNetworkSecurityGroupRules

    subnetName: operationsSubnetName
    subnetAddressPrefix: operationsSubnetAddressPrefix
    subnetServiceEndpoints: operationsSubnetServiceEndpoints
  }
}

module sharedServices './modules/spokeNetwork.bicep' = {
  name: 'deploy-sharedServices-spoke-${nowUtc}'
  scope: resourceGroup(sharedServicesSubscriptionId, sharedServicesResourceGroupName)
  params: {
    location: sharedServicesLocation
    tags: tags

    logStorageAccountName: sharedServicesLogStorageAccountName
    logStorageSkuName: sharedServicesLogStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.id

    firewallPrivateIPAddress: hub.outputs.firewallPrivateIPAddress

    virtualNetworkName: sharedServicesVirtualNetworkName
    virtualNetworkAddressPrefix: sharedServicesVirtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: sharedServicesVirtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: sharedServicesVirtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: sharedServicesNetworkSecurityGroupName
    networkSecurityGroupRules: sharedServicesNetworkSecurityGroupRules

    subnetName: sharedServicesSubnetName
    subnetAddressPrefix: sharedServicesSubnetAddressPrefix
    subnetServiceEndpoints: sharedServicesSubnetServiceEndpoints
  }
}

//// peering

module hubVirtualNetworkPeerings './modules/hubNetworkPeerings.bicep' = {
  name: 'deploy-hub-peerings-${nowUtc}'
  scope: subscription(hubSubscriptionId)
  params: {
    hubResourceGroupName: hubResourceGroup.outputs.name
    hubVirtualNetworkName: hub.outputs.virtualNetworkName

    identityVirtualNetworkName: identity.outputs.virtualNetworkName
    operationsVirtualNetworkName: operations.outputs.virtualNetworkName
    sharedServicesVirtualNetworkName: sharedServices.outputs.virtualNetworkName

    identityVirtualNetworkResourceId: identity.outputs.virtualNetworkResourceId
    operationsVirtualNetworkResourceId: sharedServices.outputs.virtualNetworkResourceId
    sharedServicesVirtualNetworkResourceId: operations.outputs.virtualNetworkResourceId
  }
}

module identityVirtualNetworkPeering './modules/spokeNetworkPeering.bicep' = {
  name: 'deploy-identity-peerings-${nowUtc}'
  scope: subscription(identitySubscriptionId)
  params: {
    spokeResourceGroupName: identityResourceGroup.outputs.name
    spokeVirtualNetworkName: identity.outputs.virtualNetworkName

    hubVirtualNetworkName: hub.outputs.virtualNetworkName
    hubVirtualNetworkResourceId: hub.outputs.virtualNetworkResourceId
  }
}

module operationsVirtualNetworkPeering './modules/spokeNetworkPeering.bicep' = {
  name: 'deploy-operations-peerings-${nowUtc}'
  scope: subscription(operationsSubscriptionId)
  params: {
    spokeResourceGroupName: operationsResourceGroup.outputs.name
    spokeVirtualNetworkName: operations.outputs.virtualNetworkName

    hubVirtualNetworkName: hub.outputs.virtualNetworkName
    hubVirtualNetworkResourceId: hub.outputs.virtualNetworkResourceId
  }
}

module sharedServicesVirtualNetworkPeering './modules/spokeNetworkPeering.bicep' = {
  name: 'deploy-sharedServices-peerings-${nowUtc}'
  scope: subscription(sharedServicesSubscriptionId)
  params: {
    spokeResourceGroupName: sharedServicesResourceGroup.outputs.name
    spokeVirtualNetworkName: sharedServices.outputs.virtualNetworkName

    hubVirtualNetworkName: hub.outputs.virtualNetworkName
    hubVirtualNetworkResourceId: hub.outputs.virtualNetworkResourceId
  }
}

//// policy

module hubPolicyAssignment './modules/policyAssignment.bicep' = {
  name: 'assign-policy-${hubResourceGroupName}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: operationsResourceGroup.outputs.name
    operationsSubscriptionId: operationsSubscriptionId
  }
}

module operationsPolicyAssignment './modules/policyAssignment.bicep' = {
  name: 'assign-policy-${operationsResourceGroupName}'
  scope: resourceGroup(operationsSubscriptionId, operationsResourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: operationsResourceGroup.outputs.name
    operationsSubscriptionId: operationsSubscriptionId
  }
}

module sharedServicesPolicyAssignment './modules/policyAssignment.bicep' = {
  name: 'assign-policy-${sharedServicesResourceGroupName}'
  scope: resourceGroup(sharedServicesSubscriptionId, sharedServicesResourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: operationsResourceGroup.outputs.name
    operationsSubscriptionId: operationsSubscriptionId
  }
}

module identityPolicyAssignment './modules/policyAssignment.bicep' = {
  name: 'assign-policy-${identityResourceGroupName}'
  scope: resourceGroup(identitySubscriptionId, identityResourceGroupName)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    logAnalyticsWorkspaceResourceGroupName: operationsResourceGroup.outputs.name
    operationsSubscriptionId: operationsSubscriptionId
  }
}

module hubSubscriptionCreateActivityLogging './modules/centralLogging.bicep' = {
  name: 'deploy-hub-sub-activity-logging'
  scope: subscription(hubSubscriptionId)
  params: {
    diagnosticSettingName: 'log-hub-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module operationsSubscriptionCreateActivityLogging './modules/centralLogging.bicep' = if(hubSubscriptionId != operationsSubscriptionId) {
  name: 'deploy-operations-sub-activity-logging'
  scope: subscription(operationsSubscriptionId)
  params: {
    diagnosticSettingName: 'log-operations-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module identitySubscriptionCreateActivityLogging './modules/centralLogging.bicep' = if(hubSubscriptionId != identitySubscriptionId) {
  name: 'deploy-identity-sub-activity-logging'
  scope: subscription(identitySubscriptionId)
  params: {
    diagnosticSettingName: 'log-identity-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

module sharedServicesSubscriptionCreateActivityLogging './modules/centralLogging.bicep' = if(hubSubscriptionId != sharedServicesSubscriptionId) {
  name: 'deploy-sharedServices-sub-activity-logging'
  scope: subscription(sharedServicesSubscriptionId)
  params: {
    diagnosticSettingName: 'log-sharedServices-sub-activity-to-${logAnalyticsWorkspace.outputs.name}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.id
  }
}

//// remote access

module remoteAccess './modules/remoteAccess.bicep' = if(deployRemoteAccess) {
  name: 'deploy-remote-access-${nowUtc}'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)

  params: {
    location: hubLocation
    
    hubVirtualNetworkName: hub.outputs.virtualNetworkName
    hubSubnetResourceId: hub.outputs.subnetResourceId
    hubNetworkSecurityGroupResourceId: hub.outputs.networkSecurityGroupResourceId

    bastionHostName: bastionHostName
    bastionHostSubnetAddressPrefix: bastionHostSubnetAddressPrefix
    bastionHostPublicIPAddressName: bastionHostPublicIPAddressName
    bastionHostPublicIPAddressSkuName: bastionHostPublicIPAddressSkuName
    bastionHostPublicIPAddressAllocationMethod: bastionHostPublicIPAddressAllocationMethod
    bastionHostPublicIPAddressAvailabilityZones: bastionHostPublicIPAddressAvailabilityZones
    bastionHostIPConfigurationName: bastionHostIPConfigurationName

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
    linuxVmNetworkInterfaceName: linuxVmNetworkInterfaceName
  }
}

// parameters

@minLength(3)
@maxLength(24)
@description('A name (3-24 alphanumeric characters in length without whitespace) used to prefix resources and generate uniqueness for resources with globally unique naming requirements like Storage Accounts and Log Analytics Workspaces')
param resourcePrefix string = 'mlz-${uniqueId}'
param hubSubscriptionId string = subscription().subscriptionId
param identitySubscriptionId string = hubSubscriptionId
param operationsSubscriptionId string = hubSubscriptionId
param sharedServicesSubscriptionId string = hubSubscriptionId

@allowed([
  'Standard'
  'Premium'
])
param firewallSkuTier string = 'Premium'

param hubResourceGroupName string = '${resourcePrefix}-hub'
param hubLocation string = deployment().location
param hubVirtualNetworkName string = 'hub-vnet'
param hubSubnetName string = 'hub-subnet'
param hubVirtualNetworkAddressPrefix string = '10.0.100.0/24'
param hubSubnetAddressPrefix string = '10.0.100.128/27'
param hubVirtualNetworkDiagnosticsLogs array = []
param hubVirtualNetworkDiagnosticsMetrics array = []
param hubNetworkSecurityGroupName string = 'hub-nsg'
param hubNetworkSecurityGroupRules array = []
param hubSubnetServiceEndpoints array = []
param hubLogStorageAccountName string = toLower(take('hublogs${uniqueId}', 24))
param hubLogStorageSkuName string = 'Standard_GRS'

param firewallName string = 'firewall'
param firewallManagementSubnetAddressPrefix string = '10.0.100.64/26'
param firewallClientSubnetAddressPrefix string = '10.0.100.0/26'
param firewallPolicyName string = 'firewall-policy'
param firewallThreatIntelMode string = 'Alert'
var firewallClientSubnetName = 'AzureFirewallSubnet' //this must be 'AzureFirewallSubnet'
param firewallClientIpConfigurationName string = 'firewall-client-ip-config'
param firewallClientSubnetServiceEndpoints array = []
param firewallClientPublicIPAddressName string = 'firewall-client-public-ip'
param firewallClientPublicIPAddressSkuName string = 'Standard'
param firewallClientPublicIpAllocationMethod string = 'Static'
param firewallClientPublicIPAddressAvailabilityZones array = []
var firewallManagementSubnetName = 'AzureFirewallManagementSubnet' //this must be 'AzureFirewallManagementSubnet'
param firewallManagementIpConfigurationName string = 'firewall-management-ip-config'
param firewallManagementSubnetServiceEndpoints array = []
param firewallManagementPublicIPAddressName string = 'firewall-management-public-ip'
param firewallManagementPublicIPAddressSkuName string = 'Standard'
param firewallManagementPublicIpAllocationMethod string = 'Static'
param firewallManagementPublicIPAddressAvailabilityZones array = []

param identityResourceGroupName string = replace(hubResourceGroupName, 'hub', 'identity')
param identityLocation string = hubLocation
param identityVirtualNetworkName string = replace(hubVirtualNetworkName, 'hub', 'identity')
param identitySubnetName string = replace(hubSubnetName, 'hub', 'identity')
param identityVirtualNetworkAddressPrefix string = '10.0.110.0/26'
param identitySubnetAddressPrefix string = '10.0.110.0/27'
param identityVirtualNetworkDiagnosticsLogs array = []
param identityVirtualNetworkDiagnosticsMetrics array = []
param identityNetworkSecurityGroupName string = replace(hubNetworkSecurityGroupName, 'hub', 'identity')
param identityNetworkSecurityGroupRules array = []
param identitySubnetServiceEndpoints array = []
param identityLogStorageAccountName string = toLower(take('idlogs${uniqueId}', 24))
param identityLogStorageSkuName string = hubLogStorageSkuName

param operationsResourceGroupName string = replace(hubResourceGroupName, 'hub', 'operations')
param operationsLocation string = hubLocation
param operationsVirtualNetworkName string = replace(hubVirtualNetworkName, 'hub', 'operations')
param operationsVirtualNetworkAddressPrefix string = '10.0.115.0/26'
param operationsVirtualNetworkDiagnosticsLogs array = []
param operationsVirtualNetworkDiagnosticsMetrics array = []
param operationsNetworkSecurityGroupName string = replace(hubNetworkSecurityGroupName, 'hub', 'operations')
param operationsNetworkSecurityGroupRules array = []
param operationsSubnetName string = replace(hubSubnetName, 'hub', 'operations')
param operationsSubnetAddressPrefix string = '10.0.115.0/27'
param operationsSubnetServiceEndpoints array = []
param operationsLogStorageAccountName string = toLower(take('opslogs${uniqueId}', 24))
param operationsLogStorageSkuName string = hubLogStorageSkuName

param sharedServicesResourceGroupName string = replace(hubResourceGroupName, 'hub', 'sharedServices')
param sharedServicesLocation string = hubLocation
param sharedServicesVirtualNetworkName string = replace(hubVirtualNetworkName, 'hub', 'sharedServices')
param sharedServicesSubnetName string = replace(hubSubnetName, 'hub', 'sharedServices')
param sharedServicesVirtualNetworkAddressPrefix string = '10.0.120.0/26'
param sharedServicesSubnetAddressPrefix string = '10.0.120.0/27'
param sharedServicesVirtualNetworkDiagnosticsLogs array = []
param sharedServicesVirtualNetworkDiagnosticsMetrics array = []
param sharedServicesNetworkSecurityGroupName string = replace(hubNetworkSecurityGroupName, 'hub', 'sharedServices')
param sharedServicesNetworkSecurityGroupRules array = []
param sharedServicesSubnetServiceEndpoints array = []
param sharedServicesLogStorageAccountName string = toLower(take('shrdSvclogs${uniqueId}', 24))
param sharedServicesLogStorageSkuName string = hubLogStorageSkuName

param logAnalyticsWorkspaceName string = take('${resourcePrefix}-laws', 63)
param logAnalyticsWorkspaceLocation string = operationsLocation
param logAnalyticsWorkspaceCappingDailyQuotaGb int = -1
param logAnalyticsWorkspaceRetentionInDays int = 30
param logAnalyticsWorkspaceSkuName string = 'PerGB2018'

@allowed([
  'NIST'
  'IL5' // Gov cloud only, trying to deploy IL5 in AzureCloud will switch to NIST
  'CMMC'
  ''
])
@description('Built-in policy assignments to assign, default is none. [NIST/IL5/CMMC] IL5 is only availalbe for GOV cloud and will switch to NIST if tried in AzureCloud.')
param policy string = ''

@description('Provision Azure Bastion Host and jumpboxes in this deployment')
param deployRemoteAccess bool = false
param bastionHostName string = 'bastionHost'
param bastionHostSubnetAddressPrefix string = '10.0.100.160/27'
param bastionHostPublicIPAddressName string = 'bastionHostPublicIPAddress'
param bastionHostPublicIPAddressSkuName string = 'Standard'
param bastionHostPublicIPAddressAllocationMethod string = 'Static'
param bastionHostPublicIPAddressAvailabilityZones array = []
param bastionHostIPConfigurationName string = 'bastionHostIPConfiguration'
param linuxVmName string = 'linuxVirtualMachine'
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
param linuxVmNetworkInterfaceName string = 'linuxVmNetworkInterface'
param linuxNetworkInterfaceIpConfigurationName string = 'linuxVmIpConfiguration'
param linuxNetworkInterfacePrivateIPAddressAllocationMethod string = 'Dynamic'

param tags object = {
  'resourcePrefix': resourcePrefix
}

param uniqueId string = uniqueString(deployment().name)
param nowUtc string = utcNow()

// outputs

output hubSubscriptionId string = hubSubscriptionId
output hubResourceGroupName string = hubResourceGroup.outputs.name
output hubResourceGroupResourceId string = hubResourceGroup.outputs.id
output hubVirtualNetworkName string = hub.outputs.virtualNetworkName
output hubVirtualNetworkResourceId string = hub.outputs.virtualNetworkResourceId
output hubSubnetName string = hub.outputs.subnetName
output hubSubnetResourceId string = hub.outputs.subnetResourceId
output hubSubnetAddressPrefix string = hub.outputs.subnetAddressPrefix
output hubNetworkSecurityGroupName string = hub.outputs.networkSecurityGroupName
output hubNetworkSecurityGroupResourceId string = hub.outputs.networkSecurityGroupResourceId
output hubFirewallPrivateIPAddress string = hub.outputs.firewallPrivateIPAddress

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.id
output firewallPrivateIPAddress string = hub.outputs.firewallPrivateIPAddress

output identitySubscriptionId string = identitySubscriptionId
output identityResourceGroupName string = identityResourceGroup.outputs.name
output identityResourceGroupResourceId string = identityResourceGroup.outputs.id
output identityVirtualNetworkName string = identity.outputs.virtualNetworkName
output identityVirtualNetworkResourceId string = identity.outputs.virtualNetworkResourceId
output identitySubnetName string = identity.outputs.subnetName
output identitySubnetResourceId string = identity.outputs.subnetResourceId
output identitySubnetAddressPrefix string = identity.outputs.subnetAddressPrefix
output identityNetworkSecurityGroupName string = identity.outputs.networkSecurityGroupName
output identityNetworkSecurityGroupResourceId string = identity.outputs.networkSecurityGroupResourceId

output operationsSubscriptionId string = operationsSubscriptionId
output operationsResourceGroupName string = operationsResourceGroup.outputs.name
output operationsResourceGroupResourceId string = operationsResourceGroup.outputs.id
output operationsVirtualNetworkName string = operations.outputs.virtualNetworkName
output operationsVirtualNetworkResourceId string = operations.outputs.virtualNetworkResourceId
output operationsSubnetName string = operations.outputs.subnetName
output operationsSubnetResourceId string = operations.outputs.subnetResourceId
output operationsSubnetAddressPrefix string = operations.outputs.subnetAddressPrefix
output operationsNetworkSecurityGroupName string = operations.outputs.networkSecurityGroupName
output operationsNetworkSecurityGroupResourceId string = operations.outputs.networkSecurityGroupResourceId

output sharedServicesSubscriptionId string = sharedServicesSubscriptionId
output sharedServicesResourceGroupName string = sharedServicesResourceGroup.outputs.name
output sharedServicesResourceGroupResourceId string = sharedServicesResourceGroup.outputs.id
output sharedServicesVirtualNetworkName string = sharedServices.outputs.virtualNetworkName
output sharedServicesVirtualNetworkResourceId string = sharedServices.outputs.virtualNetworkResourceId
output sharedServicesSubnetName string = sharedServices.outputs.subnetName
output sharedServicesSubnetResourceId string = sharedServices.outputs.subnetResourceId
output sharedServicesSubnetAddressPrefix string = sharedServices.outputs.subnetAddressPrefix
output sharedServicesNetworkSecurityGroupName string = sharedServices.outputs.networkSecurityGroupName
output sharedServicesNetworkSecurityGroupResourceId string = sharedServices.outputs.networkSecurityGroupResourceId
