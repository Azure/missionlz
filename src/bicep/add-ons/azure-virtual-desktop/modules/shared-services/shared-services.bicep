targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param identifier string
param identifierHub string
param locationControlPlane string
param mlzTags object
param names object
param networkName string
param sharedServicesSubnetResourceId string
param workspaceGlobalPrivateDnsZoneResourceId string

var resourceGroupWorkspaceGlobal = '${replace(replace(names.resourceGroup, identifier, identifierHub), networkName, 'sharedServices')}${delimiter}avdGlobalWorkspace'

// Deploys the resource group for the AVD global workspace in the shared services subscription
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupWorkspaceGlobal
  location: locationControlPlane
  tags: mlzTags
}

// Deploys the AVD global workspace in the shared services subscription and network
module workspace_global 'workspace-global.bicep' = {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    globalWorkspacePrivateDnsZoneResourceId: workspaceGlobalPrivateDnsZoneResourceId
    location: locationControlPlane
    subnetResourceId: sharedServicesSubnetResourceId
    tags: mlzTags
    workspaceGlobalName: '${replace(replace(names.workspace, identifier, identifierHub), networkName, 'sharedServices')}${delimiter}global'
    workspaceGlobalNetworkInterfaceName: '${replace(replace(names.workspaceNetworkInterface, identifier, identifierHub), networkName, 'sharedServices')}${delimiter}global'
    workspaceGlobalPrivateEndpointName: '${replace(replace(names.workspacePrivateEndpoint, identifier, identifierHub), networkName, 'sharedServices')}${delimiter}global'
  }
}
