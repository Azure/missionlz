targetScope = 'subscription'

param activeDirectorySolution string
param avdObjectId string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param delimiter string
param deploymentNameSuffix string
param desktopFriendlyName string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableApplicationInsights bool
param enableAvdInsights bool
param environmentAbbreviation string
param existingFeedWorkspaceResourceId string
param fslogixStorageService string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param location string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param maxSessionLimit int
param mlzTags object
param namingConvention object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param resourceAbbreviations object
param securityPrincipalObjectIds array
param subnetResourceId string
param tags object
param tier object
param tokens object
param validationEnvironment bool
@secure()
param virtualMachineAdminPassword string
param virtualMachineAdminUsername string
param virtualMachineSize string
param workspaceFriendlyName string
param workspacePublicNetworkAccess string

var galleryImageOffer = empty(imageVersionResourceId) ? '"${imageOffer}"' : 'null'
var galleryImagePublisher = empty(imageVersionResourceId) ? '"${imagePublisher}"' : 'null'
var galleryImageSku = empty(imageVersionResourceId) ? '"${imageSku}"' : 'null'
var galleryItemId = empty(imageVersionResourceId) ? '"${imagePublisher}.${imageOffer}${imageSku}"' : 'null'
var hostPoolResourceId = resourceId(subscription().subscriptionId, resourceGroupManagement, 'Microsoft.DesktopVirtualization/hostpools', replace(tier.namingConvention.hostPool, '${delimiter}${tokens.purpose}', ''))
var imageType = empty(imageVersionResourceId) ? '"Gallery"' : '"CustomImage"'
var resourceGroupFslogix = replace(tier.namingConvention.resourceGroup, tokens.purpose, 'fslogix')
var resourceGroupManagement = replace(tier.namingConvention.resourceGroup, tokens.purpose, 'management')

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupManagement
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Resources/resourceGroups'] ?? {}, mlzTags)
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableApplicationInsights || enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: rg
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    location: location
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    names: tier.namingConvention
    privateLinkScopeResourceId: privateLinkScopeResourceId
    tags: tags
    tokens: tokens
  }
}

/* module recoveryServicesVault 'recoveryServicesVault.bicep' = if (recoveryServices) {
  name: 'deploy-rsv-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    azureQueueStoragePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
    deployFslogix: deployFslogix
    hostPoolResourceId: hostPool.outputs.resourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    recoveryServicesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => startsWith(name, 'privatelink.${recoveryServicesGeo}.backup.windowsazure'))[0]}'
    recoveryServicesVaultName: replace(tier.namingConvention.recoveryServicesVault, '${delimiter}${tokens.purpose}', '')
    recoveryServicesVaultNetworkInterfaceName: replace(tier.namingConvention.recoveryServicesVaultNetworkInterface, '${delimiter}${tokens.purpose}', '')
    recoveryServicesVaultPrivateEndpointName: replace(tier.namingConvention.recoveryServicesVaultPrivateEndpoint, '${delimiter}${tokens.purpose}', '')
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
} */

module deploymentUserAssignedIdentity 'user-assigned-identity.bicep' = {
  scope: rg
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: location
    name: replace(tier.namingConvention.userAssignedIdentity, tokens.purpose, 'deployment')
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
  }
}

// Role Assignment for Autoscale
// Purpose: assigns the Desktop Virtualization Power On Off Contributor role to the 
// Azure Virtual Desktop service to scale the host pool
resource roleAssignment_Autoscale 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdObjectId, '40c5ff49-9181-41f8-ae61-143b0e78555e', subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '40c5ff49-9181-41f8-ae61-143b0e78555e')
    principalId: avdObjectId
  }
}

// Role Assignment for the AVD host pool
// Purpose: assigns the Desktop Virtualization Contributor role to the managed identity on the 
// management virtual machine to set the drain mode on the AVD session hosts and manage the scaling plan
module roleAssignment_Management '../common/role-assignments/resource-group.bicep' = {
  name: 'assign-role-mgmt-${deploymentNameSuffix}'
  scope: rg
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '082f0a83-3be5-4ba1-904c-961cca79b387'
  }
}

module diskAccess 'disk-access.bicep' = {
  scope: rg
  name: 'deploy-disk-access-${deploymentNameSuffix}'
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    delimiter: delimiter
    hostPoolResourceId: hostPoolResourceId
    location: location
    mlzTags: mlzTags
    names: tier.namingConvention
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tokens: tokens
  }
}

// Sets an Azure policy to disable public network access to managed disks
module policy 'policy.bicep' = {
  name: 'deploy-policy-disks-${deploymentNameSuffix}'
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
  }
}

// Sets an Azure policy to disable public network access to managed disks
module policyAssignment 'policy-assignment.bicep' = {
  name: 'assign-policy-diskAccess-${deploymentNameSuffix}'
  scope: rg
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
    location: location
    policyDefinitionId: policy.outputs.policyDefinitionId
    policyDisplayName: policy.outputs.policyDisplayName
    policyName: policy.outputs.policyDisplayName
  }
}

module customerManagedKeys '../../../../modules/customer-managed-keys.bicep' = {
  name: 'deploy-cmk-${deploymentNameSuffix}'
  scope: rg
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    environmentAbbreviation: environmentAbbreviation
    keyName: replace(tier.namingConvention.diskEncryptionSet, tokens.purpose, 'cmk')
    keyVaultPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'vaultcore'))[0]}'
    location: location
    resourceAbbreviations: resourceAbbreviations
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tier: tier
    tokens: tokens
    type: 'virtualMachine'
  }
}

// Management Virtual Machine
// Purpose: deploys the management VM which is used to execute PowerShell scripts.
module virtualMachine 'virtual-machine.bicep' = {
  name: 'deploy-mgmt-vm-${deploymentNameSuffix}'
  scope: rg
  params: {
    activeDirectorySolution: activeDirectorySolution
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: customerManagedKeys.outputs.diskEncryptionSetResourceId
    diskName: replace(tier.namingConvention.virtualMachineDisk, tokens.purpose, 'mgt')
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    hostPoolResourceId: hostPoolResourceId
    location: location
    mlzTags: mlzTags
    networkInterfaceName: replace(tier.namingConvention.virtualMachineNetworkInterface, tokens.purpose, 'mgt')
    organizationalUnitPath: organizationalUnitPath
    subnetResourceId: tier.subnets[0].id
    tags: tags
    virtualMachineAdminPassword: virtualMachineAdminPassword
    virtualMachineAdminUsername: virtualMachineAdminUsername
    virtualMachineName: replace(tier.namingConvention.virtualMachine, tokens.purpose, 'mgt')
    virtualMachineSize: virtualMachineSize
  }
}

// Deploys the Auto Increase Premium File Share Quota solution on an Azure Function App
module functionApp 'function-app.bicep' = if (fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-function-app-${deploymentNameSuffix}'
  scope: rg
  params: {
    delegatedSubnetResourceId: filter(tier.subnets, subnet => contains(subnet.name, 'function-app-outbound'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolResourceId: hostPoolResourceId
    logAnalyticsWorkspaceResourceId: enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
    mlzTags: mlzTags
    names: tier.namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupFslogix: resourceGroupFslogix
    subnetResourceId: tier.subnets[0].id
    tags: tags
    tokens: tokens
  }
}

module hostPool 'host-pool.bicep' = {
  name: 'deploy-vdpool-${deploymentNameSuffix}'
  scope: rg
  params: {
    activeDirectorySolution: activeDirectorySolution
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    customImageId: customImageId
    customRdpProperty: customRdpProperty
    diskSku: diskSku
    domainName: domainName
    enableAvdInsights: enableAvdInsights
    galleryImageOffer: galleryImageOffer
    galleryImagePublisher: galleryImagePublisher
    galleryImageSku: galleryImageSku
    galleryItemId: galleryItemId
    hostPoolDiagnosticSettingName: replace(namingConvention.hostPoolDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    hostPoolName: replace(namingConvention.hostPool, '${delimiter}${tokens.purpose}', '')
    hostPoolNetworkInterfaceName: replace(namingConvention.hostPoolNetworkInterface, '${delimiter}${tokens.purpose}', '')
    hostPoolPrivateEndpointName: replace(namingConvention.hostPoolPrivateEndpoint, '${delimiter}${tokens.purpose}', '')
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: location
    logAnalyticsWorkspaceResourceId: enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    sessionHostNamePrefix: replace(namingConvention.virtualMachine, '${delimiter}${tokens.purpose}', '')
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    virtualMachineSize: virtualMachineSize
  }
}

module applicationGroup 'application-group.bicep' = {
  name: 'deploy-vdag-${deploymentNameSuffix}'
  scope: rg
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentity.outputs.clientId
    desktopApplicationGroupName: replace(namingConvention.applicationGroup, '${delimiter}${tokens.purpose}', '')
    hostPoolResourceId: hostPool.outputs.resourceId
    location: location
    mlzTags: mlzTags
    securityPrincipalObjectIds: securityPrincipalObjectIds
    desktopFriendlyName: desktopFriendlyName
    tags: tags
    virtualMachineName: virtualMachine.outputs.name
  }
}

module roleAssignment '../common/role-assignments/resource-group.bicep' = if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(split(existingFeedWorkspaceResourceId, '/')[4]) // scope to the resource group of the existing feed workspace
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '21efdde3-836f-432b-bf3d-3e8e734d4b2b' // Desktop Virtualization Workspace Contributor (Purpose: update the app group references on an existing feed workspace)
  }
}

// Deploys the resources to create and configure the feed workspace
module workspace_feed 'workspace-feed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: rg
  params: {
    applicationGroupResourceId: applicationGroup.outputs.resourceId
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPool.outputs.resourceId
    location: location
    logAnalyticsWorkspaceResourceId: enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
    mlzTags: mlzTags
    subnetResourceId: subnetResourceId
    tags: tags
    workspaceFeedDiagnoticSettingName: replace(namingConvention.workspaceDiagnosticSetting, tokens.purpose, 'feed')
    workspaceFeedName: replace(namingConvention.workspace, tokens.purpose, 'feed')
    workspaceFeedNetworkInterfaceName: replace(namingConvention.workspaceNetworkInterface, tokens.purpose, 'feed')
    workspaceFeedPrivateEndpointName: replace(namingConvention.workspacePrivateEndpoint, tokens.purpose, 'feed')
    workspaceFriendlyName: empty(workspaceFriendlyName) ? replace(namingConvention.workspace, '${delimiter}${tokens.purpose}', '') : '${workspaceFriendlyName} (${location})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentity.outputs.clientId
    existingFeedWorkspaceResourceId: existingFeedWorkspaceResourceId
    virtualMachineName: virtualMachine.outputs.name
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring!.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output diskAccessPolicyDefinitionId string = policy.outputs.policyDefinitionId
output diskAccessPolicyDisplayName string = policy.outputs.policyDisplayName
output diskAccessResourceId string = diskAccess.outputs.resourceId
output diskEncryptionSetResourceId string = customerManagedKeys.outputs.diskEncryptionSetResourceId
output encryptionUserAssignedIdentityResourceId string = customerManagedKeys.outputs.userAssignedIdentityResourceId
output functionAppPrincipalId string = fslogixStorageService == 'AzureFiles Premium' ? functionApp!.outputs.functionAppPrincipalId : ''
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
output keyVaultName string = customerManagedKeys.outputs.keyVaultName
output keyVaultUri string = customerManagedKeys.outputs.keyVaultUri
output logAnalyticsWorkspaceName string = enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableApplicationInsights || enableAvdInsights ? monitoring!.outputs.logAnalyticsWorkspaceResourceId : ''
output resourceGroupName string = rg.name
output virtualMachineName string = virtualMachine.outputs.name
output virtualMachineResourceId string = virtualMachine.outputs.resourceId
