targetScope = 'subscription'

param deploymentNameSuffix string
param deploymentUserAssignedIdentityPrincipalId string
param enableApplicationInsights bool
param enableAvdInsights bool
param environmentAbbreviation string
param existingApplicationGroupReferences array
param existingFeedWorkspaceResourceId string
param fslogixStorageService string
param locationControlPlane string
param locationVirtualMachines string
param logAnalyticsWorkspaceRetention int
param logAnalyticsWorkspaceSku string
param privateDnsZoneResourceIdPrefix string
param privateDnsZones array
param privateLinkScopeResourceId string
param tags object
param tier object

var hostPoolResourceId = '${subscription().id}/resourceGroups/${resourceGroupManagement}/providers/Microsoft.DesktopVirtualization/hostpools/${tier.namingConvention.hostPool}'
var resourceGroupShared = '${tier.namingConvention.resourceGroup}${tier.delimiter}shared'
var resourceGroupFslogix = '${tier.namingConvention.resourceGroup}${tier.delimiter}fslogix'
var resourceGroupManagement = '${tier.namingConvention.resourceGroup}${tier.delimiter}management'

// Deploys the resource group for the shared resources
resource resourceGroup_shared 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupShared
  location: locationControlPlane
  tags: union(tags[?'Microsoft.Resources/resourceGroups'] ?? {}, tier.mlzTags)
}

// Monitoring Resources for AVD Insights
// This module deploys a Log Analytics Workspace with a Data Collection Rule 
module monitoring 'monitoring.bicep' = if (enableApplicationInsights || enableAvdInsights) {
  name: 'deploy-monitoring-${deploymentNameSuffix}'
  scope: resourceGroup_shared
  params: {
    delimiter: tier.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableAvdInsights: enableAvdInsights
    hostPoolResourceId: hostPoolResourceId
    location: locationVirtualMachines
    logAnalyticsWorkspaceRetention: logAnalyticsWorkspaceRetention
    logAnalyticsWorkspaceSku: logAnalyticsWorkspaceSku
    mlzTags: tier.mlzTags
    names: tier.namingConvention
    privateLinkScopeResourceId: privateLinkScopeResourceId
    tags: tags
  }
}

// Role assignments needed to update the application groups on the existing feed workspace
module roleAssignments_appGroupReferences '../common/role-assignments/resource-group.bicep' = [for (appGroup, i) in existingApplicationGroupReferences: if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${i}-${deploymentNameSuffix}'
  scope: resourceGroup(split(appGroup, '/')[2], split(appGroup, '/')[4])
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '86240b0e-9422-4c43-887b-b61143f32ba8' // Desktop Virtualization Application Group Contributor (Purpose: update the app group references on an existing feed workspace)
  }
  dependsOn: [
    resourceGroup_shared
  ]
}]

module roleAssignment '../common/role-assignments/resource-group.bicep' = if (!empty(existingFeedWorkspaceResourceId)) {
  name: 'assign-role-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup_shared
  params: {
    principalId: deploymentUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '21efdde3-836f-432b-bf3d-3e8e734d4b2b' // Desktop Virtualization Workspace Contributor (Purpose: update the app group references on an existing feed workspace)
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
  scope: resourceGroup_shared
  params: {
    delegatedSubnetResourceId: filter(tier.subnets, subnet => contains(subnet.name, 'function-app-outbound'))[0].id
    delimiter: tier.delimiter
    deploymentNameSuffix: deploymentNameSuffix
    enableApplicationInsights: enableApplicationInsights
    environmentAbbreviation: environmentAbbreviation
    hostPoolResourceId: hostPoolResourceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    mlzTags: tier.mlzTags
    names: tier.namingConvention
    privateDnsZoneResourceIdPrefix: privateDnsZoneResourceIdPrefix
    privateDnsZones: privateDnsZones
    privateLinkScopeResourceId: privateLinkScopeResourceId
    resourceGroupFslogix: resourceGroupFslogix
    subnetResourceId: tier.subnets[0].id
    tags: tags
  }
}

output dataCollectionRuleResourceId string = enableAvdInsights ? monitoring.outputs.dataCollectionRuleResourceId : ''
output functionAppPrincipalId string = fslogixStorageService == 'AzureFiles Premium' ? functionApp.outputs.functionAppPrincipalId : ''
output logAnalyticsWorkspaceName string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceName : ''
output logAnalyticsWorkspaceResourceId string = enableApplicationInsights || enableAvdInsights ? monitoring.outputs.logAnalyticsWorkspaceResourceId : ''
output resourceGroupName string = resourceGroup_shared.name
