targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param enableApplicationInsights bool
param enableAvdInsights bool
param environmentAbbreviation string
param existingApplicationGroupReferences array
param existingFeedWorkspaceResourceId string
param existingWorkspace bool
param fslogixStorageService string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param mlzTags object
param names object
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
// param recoveryServices bool
// param recoveryServicesGeo string
param stampIndexFull string
param sharedServicesSubnetResourceId string
// param storageService string
param subnetResourceId string
param subnets array
param tags object
// param timeZone string

var hostPoolResourceId = '${subscription().id}}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${names.hostPool}'
var resourceGroupShared = replace(names.resourceGroup, stampIndexFull, 'shared')
var resourceGroupFslogix = '${names.resourceGroup}${delimiter}fslogix'
var resourceGroupManagement = '${names.resourceGroup}${delimiter}management'
var userAssignedIdentityNamePrefix = replace(names.userAssignedIdentity, stampIndexFull, '')

// Resource group for the feed workspace
module rg_shared '../../../../modules/resource-group.bicep' = if (!existingWorkspace) {
  name: 'deploy-rg-vdws-feed-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    location: locationControlPlane
    mlzTags: mlzTags
    name: resourceGroupShared
    tags: {}
  }
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableApplicationInsights || enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupShared)
  params: {
    delimiter: delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    location: locationVirtualMachines
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: mlzTags
    names: names
    privateLinkScopeResourceId: privateLinkScopeResourceId
    stampIndexFull: stampIndexFull
    tags: tags
  }
  dependsOn: [
    rg_shared
  ]
}

module diskAccess 'disk-access.bicep' = {
  scope: resourceGroup(resourceGroupShared)
  name: 'deploy-disk-access-${deploymentNameSuffix}'
  params: {
    azureBlobsPrivateDnsZoneResourceId: '${privateDnsZoneResourceIdPrefix}${filter(privateDnsZones, name => contains(name, 'blob'))[0]}'
    delimiter: delimiter
    hostPoolResourceId: hostPoolResourceId
    location: locationVirtualMachines
    mlzTags: mlzTags
    names: names
    stampIndexFull: stampIndexFull
    subnetResourceId: subnetResourceId
    tags: tags
  }
  dependsOn: [
    rg_shared
  ]
}

// Sets an Azure policy to disable public network access to managed disks
module policy 'policy.bicep' = {
  name: 'deploy-policy-disks-${deploymentNameSuffix}'
  params: {
    diskAccessResourceId: diskAccess.outputs.resourceId
  }
}

module deploymentUserAssignedIdentity 'user-assigned-identity.bicep' = {
  scope: resourceGroup(resourceGroupShared)
  name: 'deploy-id-deployment-${deploymentNameSuffix}'
  params: {
    location: locationVirtualMachines
    name: '${userAssignedIdentityNamePrefix}deployment'
    tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}, mlzTags)
  }
  dependsOn: [
    rg_shared
  ]
}

// Role assignments needed to update the application groups on the existing feed workspace
module roleAssignments_appGroupReferences '../common/role-assignments/resource-group.bicep' = [for (appGroup, i) in existingApplicationGroupReferences: if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(appGroup, '/')[2], split(appGroup, '/')[4])
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '86240b0e-9422-4c43-887b-b61143f32ba8' // Desktop Virtualization Application Group Contributor (Purpose: update the app group references on an existing feed workspace)
  }
  dependsOn: [
    rg_shared
  ]
}]

module roleAssignment '../common/role-assignments/resource-group.bicep' = if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupShared)
  params: {
    principalId: deploymentUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '21efdde3-836f-432b-bf3d-3e8e734d4b2b' // Desktop Virtualization Workspace Contributor (Purpose: update the app group references on an existing feed workspace)
  }
  dependsOn: [
    rg_shared
  ]
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
    recoveryServicesVaultName: namingConvention.recoveryServicesVault
    recoveryServicesVaultNetworkInterfaceName: namingConvention.recoveryServicesVaultNetworkInterface
    recoveryServicesVaultPrivateEndpointName: namingConvention.recoveryServicesVaultPrivateEndpoint
    storageService: storageService
    subnetId: subnetResourceId
    tags: tags
    timeZone: timeZone
  }
} */

// Deploys the Auto Increase Premium File Share Quota solution on an Azure Function App
module functionApp 'function-app.bicep' = if (fslogixStorageService == 'AzureFiles Premium') {
  name: 'deploy-function-app-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupShared)
  params: {
    delegatedSubnetResourceId: filter(subnets, subnet => contains(subnet.name, 'FunctionAppOutbound'))[0].id
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolResourceId: hostPoolResourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    names: names
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupFslogix: resourceGroupFslogix
    stampIndexFull: stampIndexFull
    subnetResourceId: subnetResourceId
    tags: tags
  }
  dependsOn: [
    rg_shared
  ]
}

output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring.outputs.dataCollectionRuleResourceId : ''
output deploymentUserAssignedIdentityClientId string = deploymentUserAssignedIdentity.outputs.clientId
output deploymentUserAssignedIdentityPrincipalId string = deploymentUserAssignedIdentity.outputs.principalId
output deploymentUserAssignedIdentityResourceId string = deploymentUserAssignedIdentity.outputs.resourceId
output diskAccessPolicyDefinitionId string = policy.outputs.policyDefinitionId
output diskAccessPolicyDisplayName string = policy.outputs.policyDisplayName
output diskAccessResourceId string = diskAccess.outputs.resourceId
output functionAppPrincipalId string = functionApp.outputs.functionAppPrincipalId
output logAnalyticsWorkspaceName string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
// output recoveryServicesVaultName string = recoveryServices ? recoveryServicesVault.outputs.name : ''
