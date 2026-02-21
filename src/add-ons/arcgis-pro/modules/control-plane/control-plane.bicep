targetScope = 'subscription'

param avdPrivateDnsZoneResourceId string
param customRdpProperty string
param delimiter string
param deploymentNameSuffix string
param hostPoolPublicNetworkAccess string
param hostPoolType string
param location string
param logAnalyticsWorkspaceResourceId string
param maxSessionLimit int
param mlzTags object
param resourceGroupName string
param securityPrincipalObjectId string
param tags object
param tier object
param tokens object
param validationEnvironment bool
param vmTemplate string
param workspaceFriendlyName string
param workspaceGlobalPrivateDnsZoneResourceId string
param workspacePublicNetworkAccess string

var namingConvention = tier.namingConvention
var subnetResourceId = tier.subnetResourceId

module hostPool 'host-pool.bicep' = {
  name: 'deploy-vdpool-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    customRdpProperty: customRdpProperty
    hostPoolDiagnosticSettingName: replace(namingConvention.hostPoolDiagnosticSetting, '${delimiter}${tokens.purpose}', '')
    hostPoolName: replace(namingConvention.hostPool, '${delimiter}${tokens.purpose}', '')
    hostPoolNetworkInterfaceName: replace(namingConvention.hostPoolNetworkInterface, '${delimiter}${tokens.purpose}', '')
    hostPoolPrivateEndpointName: replace(namingConvention.hostPoolPrivateEndpoint, '${delimiter}${tokens.purpose}', '')
    hostPoolPublicNetworkAccess: hostPoolPublicNetworkAccess
    hostPoolType: hostPoolType
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    maxSessionLimit: maxSessionLimit
    mlzTags: mlzTags
    subnetResourceId: subnetResourceId
    tags: tags
    validationEnvironment: validationEnvironment
    vmTemplate: vmTemplate
  }
}

module applicationGroup 'application-group.bicep' = {
  name: 'deploy-vdag-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    desktopApplicationGroupName: replace(namingConvention.applicationGroup, '${delimiter}${tokens.purpose}', '')
    hostPoolResourceId: hostPool.outputs.resourceId
    locationControlPlane: location
    mlzTags: mlzTags
    securityPrincipalObjectId: securityPrincipalObjectId
    tags: tags
  }
}

// Deploys the resources to create and configure the feed workspace
module workspace_feed 'workspace-feed.bicep' = {
  name: 'deploy-vdws-feed-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    applicationGroupResourceId: applicationGroup.outputs.resourceId
    avdPrivateDnsZoneResourceId: avdPrivateDnsZoneResourceId
    locationControlPlane: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    mlzTags: mlzTags
    subnetResourceId: subnetResourceId
    workspaceFeedDiagnoticSettingName: replace(namingConvention.workspaceDiagnosticSetting, tokens.purpose, 'feed')
    workspaceFeedName: replace(namingConvention.workspace, tokens.purpose, 'feed')
    workspaceFeedNetworkInterfaceName: replace(namingConvention.workspaceNetworkInterface, tokens.purpose, 'feed')
    workspaceFeedPrivateEndpointName: replace(namingConvention.workspacePrivateEndpoint, tokens.purpose, 'feed')
    workspaceFriendlyName: empty(workspaceFriendlyName) ? replace(namingConvention.workspace, '${delimiter}${tokens.purpose}', '') : '${workspaceFriendlyName} (${location})'
    workspacePublicNetworkAccess: workspacePublicNetworkAccess
  }
}

// Deploys the AVD global workspace
module workspace_global '../../../azure-virtual-desktop/modules/shared-services/workspace-global.bicep' = {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    globalWorkspacePrivateDnsZoneResourceId: workspaceGlobalPrivateDnsZoneResourceId
    location: location
    subnetResourceId: subnetResourceId
    tags: mlzTags
    workspaceGlobalName: replace(namingConvention.workspace, tokens.purpose, 'global')
    workspaceGlobalNetworkInterfaceName: replace(namingConvention.workspaceNetworkInterface, tokens.purpose, 'global')
    workspaceGlobalPrivateEndpointName: replace(namingConvention.workspacePrivateEndpoint, tokens.purpose, 'global')
  }
}

output hostPoolResourceId string = hostPool.outputs.resourceId
