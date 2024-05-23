param diskAccessName string
param hostPoolName string
param location string
param mlzTags object
param resourceGroupControlPlane string
param subnetResourceId string
param tags object

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: diskAccessName
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.Compute/diskAccesses') ? tags['Microsoft.Compute/diskAccesses'] : {}, mlzTags)
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${diskAccessName}'
  location: location
  tags: union({
    'cm-resource-parent': '${subscription().id}}/resourceGroups/${resourceGroupControlPlane}/providers/Microsoft.DesktopVirtualization/hostpools/${hostPoolName}'
  }, contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}, mlzTags)
  properties: {
    customNetworkInterfaceName: 'nic-${diskAccessName}'
    privateLinkServiceConnections: [
      {
        name: 'pe-${diskAccessName}'
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
