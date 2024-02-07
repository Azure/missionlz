param globalWorkspacePrivateDnsZoneResourceId string
param location string
param subnetResourceId string
param workspaceNamePrefix string

var globalWorkspaceName = '${workspaceNamePrefix}-global'
var privateEndpointName = 'pe-${globalWorkspaceName}'

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: globalWorkspaceName
  location: location
  tags: {}
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: privateEndpointName
  location: location
  tags: {}
  properties: {
    customNetworkInterfaceName: 'nic-${globalWorkspaceName}'
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
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
