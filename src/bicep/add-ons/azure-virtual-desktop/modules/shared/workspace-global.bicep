param globalWorkspacePrivateDnsZoneResourceId string
param location string
param subnetResourceId string
param tags object
param workspaceGlobalName string
param workspaceGlobalNetworkInterfaceName string
param workspaceGlobalPrivateEndpointName string

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: workspaceGlobalName
  location: location
  tags: tags
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: workspaceGlobalPrivateEndpointName
  location: location
  tags: tags
  properties: {
    customNetworkInterfaceName: workspaceGlobalNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: workspaceGlobalPrivateEndpointName
        properties: {
          privateLinkServiceId: workspace.id
          groupIds: [
            'global'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: replace(split(globalWorkspacePrivateDnsZoneResourceId, '/')[8], '.', '-')
        properties: {
          privateDnsZoneId: globalWorkspacePrivateDnsZoneResourceId
        }
      }
    ]
  }
}
