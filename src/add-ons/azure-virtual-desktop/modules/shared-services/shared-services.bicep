targetScope = 'subscription'

param delimiter string
param deploymentNameSuffix string
param identifier string
param identifierHub string
param locationControlPlane string
param sharedServicesSubnetResourceId string
param tier object
param workspaceGlobalPrivateDnsZoneResourceId string

var resourceGroupWorkspaceGlobal = '${replace(replace(tier.namingConvention.resourceGroup, identifier, identifierHub), tier.name, 'sharedServices')}${delimiter}avdGlobalWorkspace'

// Deploys the resource group for the AVD global workspace in the shared services subscription
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupWorkspaceGlobal
  location: locationControlPlane
  tags: tier.mlzTags
}

// Deploys the AVD global workspace in the shared services subscription and network
module workspace_global 'workspace-global.bicep' = {
  name: 'deploy-vdws-global-${deploymentNameSuffix}'
  scope: resourceGroup
  params: {
    globalWorkspacePrivateDnsZoneResourceId: workspaceGlobalPrivateDnsZoneResourceId
    location: locationControlPlane
    subnetResourceId: sharedServicesSubnetResourceId
    tags: tier.mlzTags
    workspaceGlobalName: '${replace(replace(tier.namingConvention.workspace, identifier, identifierHub), tier.name, 'sharedServices')}${delimiter}global'
    workspaceGlobalNetworkInterfaceName: '${replace(replace(tier.namingConvention.workspaceNetworkInterface, identifier, identifierHub), tier.name, 'sharedServices')}${delimiter}global'
    workspaceGlobalPrivateEndpointName: '${replace(replace(tier.namingConvention.workspacePrivateEndpoint, identifier, identifierHub), tier.name, 'sharedServices')}${delimiter}global'
  }
}
