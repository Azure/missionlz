targetScope = 'subscription'

param deploymentNameSuffix string
param existingWorkspace bool
param globalWorkspacePrivateDnsZoneResourceId string
param sharedServicesSubnetResourceId string
param mlzTags object
param resourceGroupName string
param workspaceGlobalName string
param workspaceGlobalNetworkInterfaceName string
param workspaceGlobalPrivateEndpointName string

module virtualNetwork 'virtualNetwork.bicep' = if (!existingWorkspace) {
  scope: resourceGroup(split(sharedServicesSubnetResourceId, '/')[4])
  name: 'get-vnet-shared-services-${deploymentNameSuffix}'
  params: {
    name: split(sharedServicesSubnetResourceId, '/')[8]
  }
}

// Resource Group for the global AVD Workspace
module rg_GlobalWorkspace '../../../../modules/resource-group.bicep' = if (!existingWorkspace) {
  name: 'deploy-rg-vdws-global-${deploymentNameSuffix}'
  scope: subscription(split(sharedServicesSubnetResourceId, '/')[2])
  params: {
    location: !existingWorkspace ? virtualNetwork.outputs.location : ''
    mlzTags: mlzTags
    name: resourceGroupName
    tags: {}
  }
}

module workspace 'workspace.bicep' = if (!existingWorkspace) {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup(resourceGroupName)
  params: {
    globalWorkspacePrivateDnsZoneResourceId: globalWorkspacePrivateDnsZoneResourceId
    location: !existingWorkspace ? virtualNetwork.outputs.location : ''
    subnetResourceId: sharedServicesSubnetResourceId
    tags: mlzTags
    workspaceGlobalName: workspaceGlobalName
    workspaceGlobalNetworkInterfaceName: workspaceGlobalNetworkInterfaceName
    workspaceGlobalPrivateEndpointName: workspaceGlobalPrivateEndpointName
  }
  dependsOn: [
    rg_GlobalWorkspace
  ]
}
