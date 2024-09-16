param hostPoolName string
param location string
param mlzTags object
param namingConvention object
param resourceGroupControlPlane string
param subnetResourceId string
param tags object

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: namingConvention.diskAccess
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.Compute/diskAccesses') ? tags['Microsoft.Compute/diskAccesses'] : {}, mlzTags)
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: namingConvention.diskAccessPrivateEndpoint
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}, mlzTags)
  properties: {
    customNetworkInterfaceName: namingConvention.diskAccessNetworkInterface
    privateLinkServiceConnections: [
      {
        name: namingConvention.diskAccessPrivateEndpoint
        properties: {
          privateLinkServiceId: diskAccess.id
          groupIds: [
            'disks'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}


output resourceId string = diskAccess.id
