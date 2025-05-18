targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param identifier string
param identifierHub string
param locationControlPlane string
param mlzTags object
param names object
param sharedServicesSubnetResourceId string
param stampIndexFull string
param workspaceGlobalPrivateDnsZoneResourceId string

var resourceGroupWorkspaceGlobal = replace(replace(names.resourceGroup, stampIndexFull, 'workspace${delimiter}global'), identifier, identifierHub)

// Resource group for the global workspace
module rg_workspace_global '../../../../modules/resource-group.bicep' = {
  name: 'deploy-rg-vdws-global-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    location: locationControlPlane
    mlzTags: mlzTags
    name: resourceGroupWorkspaceGlobal
    tags: {}
  }
}

// Global workspace
module workspace_global 'workspace-global.bicep' = {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupWorkspaceGlobal)
  params: {
    globalWorkspacePrivateDnsZoneResourceId: workspaceGlobalPrivateDnsZoneResourceId
    location: locationControlPlane
    subnetResourceId: sharedServicesSubnetResourceId
    tags: mlzTags
    workspaceGlobalName: replace(replace(names.workspace, stampIndexFull, 'global'), identifier, identifierHub)
    workspaceGlobalNetworkInterfaceName: replace(replace(names.workspaceNetworkInterface, stampIndexFull, 'global'), identifier, identifierHub)
    workspaceGlobalPrivateEndpointName: replace(replace(names.workspacePrivateEndpoint, stampIndexFull, 'global'), identifier, identifierHub)
  }
  dependsOn: [
    rg_workspace_global
  ]
}
