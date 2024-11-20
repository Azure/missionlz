targetScope = 'subscription'

param activeDirectorySolution string
param avdObjectId string
param avdPrivateDnsZoneResourceId string
param customImageId string
param customRdpProperty string
param deployFslogix bool
param deploymentNameSuffix string
param desktopFriendlyName string
param diskEncryptionSetResourceId string
param diskSku string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableApplicationInsights bool
param enableAvdInsights bool
param environmentAbbreviation string
param fslogixStorageService string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param imageOffer string
param imagePublisher string
param imageSku string
param imageVersionResourceId string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param maxSessionLimit int
param mlzTags object
param namingConvention object
param organizationalUnitPath string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param recoveryServices bool
param recoveryServicesGeo string
param resourceAbbreviations object
param resourceGroupHosts string
param resourceGroupManagement string
param resourceGroupStorage string
param securityPrincipalObjectIds array
param serviceToken string
param sessionHostNamePrefix string
param storageService string
param subnetResourceId string
param subnets array
param tags object
param timeDifference string
param timeZone string
param validationEnvironment bool
@secure()
param virtualMachinePassword string
param virtualMachineSize string
param virtualMachineUsername string

var galleryImageOffer = empty(imageVersionResourceId) ? '"${imageOffer}"' : 'null'
var galleryImagePublisher = empty(imageVersionResourceId) ? '"${imagePublisher}"' : 'null'
var galleryImageSku = empty(imageVersionResourceId) ? '"${imageSku}"' : 'null'
var galleryItemId = empty(imageVersionResourceId) ? '"${imagePublisher}.${imageOffer}${imageSku}"' : 'null'
var hostPoolName = namingConvention.hostPool
var imageType = empty(imageVersionResourceId) ? '"Gallery"' : '"CustomImage"'
var userAssignedIdentityNamePrefix = namingConvention.userAssignedIdentity

// Role Assignment for Autoscale
// Purpose: assigns the Desktop Virtualization Power On Off Contributor role to the 
// Azure Virtual Desktop service to scale the host pool
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdObjectId, '40c5ff49-9181-41f8-ae61-143b0e78555e', subscription().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '40c5ff49-9181-41f8-ae61-143b0e78555e')
    principalId: avdObjectId
  }
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableApplicationInsights || enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
    location: locationVirtualMachines
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    namingConvention: namingConvention
    privateLinkScopeResourceId: privateLinkScopeResourceId
    serviceToken: serviceToken
    tags: tags
  }
}

module hostPool 'hostPool.bicep' = {
  name: 'deploy-vdpool-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
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
    hostPoolDiagnosticSettingName: namingConvention.hostPoolDiagnosticSetting
    hostPoolName: hostPoolName
    hostPoolNetworkInterfaceName: namingConvention.hostPoolNetworkInterface
    hostPoolPrivateEndpointName: namingConvention.hostPoolPrivateEndpoint
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    imageType: imageType
    location: locationControlPlane
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    sessionHostNamePrefix: sessionHostNamePrefix
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    virtualMachineSize: virtualMachineSize
  }
}

module diskAccess 'diskAccess.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'deploy-disk-access-${deploymentNameSuffix}'
  params: {
    hostPoolResourceId: hostPool.outputs.resourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    namingConvention: namingConvention
    subnetResourceId: subnetResourceId
    tags: tags
  }
}

// Sets an Azure policy to disable public network access to managed disks
module policy 'policy.bicep' = {
  name: 'deploy-policy-disks-${deploymentNameSuffix}'
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
    location: locationVirtualMachines
    resourceGroupName: resourceGroupHosts
  }
}

module deploymentUserAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(resourceGroupManagement)
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: replace(userAssignedIdentityNamePrefix, serviceToken, 'deployment')
    tags: union({'cm-resource-parent': hostPool.outputs.resourceId}, tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
  }
}


// Role Assignment for the AVD host pool
// Purpose: assigns the Desktop Virtualization Contributor role to the managed identity on the 
// management virtual machine to set the drain mode on the AVD session hosts and manage the scaling plan
module roleAssignment_Management '../common/roleAssignments/resourceGroup.bicep' = {
  name: 'assign-role-mgmt-${deploymentNameSuffix}'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupManagement)
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '082f0a83-3be5-4ba1-904c-961cca79b387'
  }
}

// Role Assignment for FSLogix
// Purpose: assigns the Storage Account Contributor role to the managed identity on the
// management virtual machine  storage resource group to domain join storage account(s) & set NTFS permissions on the file share(s)
module roleAssignment_Storage '../common/roleAssignments/resourceGroup.bicep' = if (deployFslogix) {
  name: 'assign-role-storage-${deploymentNameSuffix}'
  scope: resourceGroup(subscription().subscriptionId, resourceGroupStorage)
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
  }
}

// Management Virtual Machine
// Purpose: deploys the management VM is required to execute PowerShell scripts.
module virtualMachine 'virtualMachine.bicep' = {
  name: 'deploy-mgmt-vm-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    deploymentUserAssignedIdentityResourceId: deploymentUserAssignedIdentity.outputs.resourceId
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    diskName: replace(namingConvention.virtualMachineDisk, serviceToken, 'mgt')
    diskSku: diskSku
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    hostPoolResourceId: hostPool.outputs.resourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    networkInterfaceName: replace(namingConvention.virtualMachineNetworkInterface, serviceToken, 'mgt')
    organizationalUnitPath: organizationalUnitPath
    subnetResourceId: subnetResourceId
    tags: tags
    virtualMachineName: replace(namingConvention.virtualMachine, serviceToken, 'mgt')
    virtualMachinePassword: virtualMachinePassword
    virtualMachineUsername: virtualMachineUsername
  }
}

module applicationGroup 'applicationGroup.bicep' = {
  name: 'deploy-vdag-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    deploymentUserAssignedIdentityClientId: deploymentUserAssignedIdentity.outputs.clientId
    deploymentUserAssignedIdentityPrincipalId: deploymentUserAssignedIdentity.outputs.principalId
    desktopApplicationGroupName: namingConvention.applicationGroup
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: locationControlPlane
    locationVirtualMachines: locationVirtualMachines
    mlzTags: mlzTags
    resourceGroupManagement: resourceGroupManagement
    securityPrincipalObjectIds: securityPrincipalObjectIds
    desktopFriendlyName: desktopFriendlyName
    tags: tags
    virtualMachineName: virtualMachine.outputs.name
  }
}

// Deploys the Auto Increase Premium File Share Quota solution on an Azure Function App
module functionApp 'functionApp.bicep' = if (deployFslogix && fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-function-app-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    delegatedSubnetResourceId: filter(subnets, subnet => contains(subnet.name, 'FunctionAppOutbound'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolResourceId: hostPool.outputs.resourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    namingConvention: namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceAbbreviations: resourceAbbreviations
    resourceGroupManagement: resourceGroupManagement
    resourceGroupStorage: resourceGroupStorage
    serviceToken: serviceToken
    subnetResourceId: subnetResourceId
    tags: tags
    timeDifference: timeDifference
  }
}

module recoveryServicesVault 'recoveryServicesVault.bicep' = if (recoveryServices) {
  name: 'deploy-rsv-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupManagement)
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    azureQueueStoragePrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'queue'))[0]}'
    deployFslogix: deployFslogix
    hostPoolResourceId: hostPool.outputs.resourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    recoveryServicesPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => startsWith(name, 'privatelink.${recoveryServicesGeo}.backup.windowsazure'))[0]}'
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    recoveryServicesVaultNetworkInterfaceName: namingConvention.recoveryServicesVaultNetworkInterface
    recoveryServicesVaultPrivateEndpointName: namingConvention.recoveryServicesVaultPrivateEndpoint
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
}

output applicationGroupResourceId string = applicationGroup.outputs.resourceId
output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output functionAppName string = fslogixStorageService == 'AzureFiles Premium' ? functionApp.outputs.functionAppName : ''
output hostPoolName string = hostPool.outputs.name
output hostPoolResourceId string = hostPool.outputs.resourceId
output logAnalyticsWorkspaceName string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
output recoveryServicesVaultName string = recoveryServices ? recoveryServicesVault.outputs.name : ''
output virtualMachineName string = virtualMachine.outputs.name
output virtualMachineResourceId string = virtualMachine.outputs.resourceId
