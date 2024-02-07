targetScope = 'subscription'

param existingWorkspace bool
param globalWorkspacePrivateDnsZoneResourceId string
param hubSubnetResourceId string
param resourceGroupName string
param timestamp string
param workspaceNamePrefix string

module virtualNetwork 'virtualNetwork.bicep' = if (!existingWorkspace) {
  scope: resourceGroup(split(hubSubnetResourceId, '/')[4])
  name: 'SharedServices_VirtualNetwork_${timestamp}'
  params: {
    name: split(hubSubnetResourceId, '/')[8]
  }
}

// Resource Group for the global AVD Workspace
module rg_GlobalWorkspace '../resourceGroup.bicep' = if (!existingWorkspace) {
  name: 'ResourceGroup_WorkspaceGlobal_${timestamp}'
  scope: subscription(split(hubSubnetResourceId, '/')[2])
  params: {
    location: !existingWorkspace ? virtualNetwork.outputs.location : ''
    resourceGroupName: resourceGroupName
    tags: {}
  }
}

module workspace 'workspace.bicep' = if (!existingWorkspace) {
  name: 'WorkspaceGlobal_${timestamp}'
  scope: resourceGroup(resourceGroupName)
  params: {
    globalWorkspacePrivateDnsZoneResourceId: globalWorkspacePrivateDnsZoneResourceId
    location: !existingWorkspace ? virtualNetwork.outputs.location : ''
    subnetResourceId: hubSubnetResourceId
    workspaceNamePrefix: workspaceNamePrefix
  }
  dependsOn: [
    rg_GlobalWorkspace
  ]
}
