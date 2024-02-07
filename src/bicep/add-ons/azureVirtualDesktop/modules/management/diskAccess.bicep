param diskAccessName string
param location string
param subnetResourceId string
param tags object

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: diskAccessName
  location: location
  tags: contains(tags, 'Microsoft.Compute/diskAccesses') ? tags['Microsoft.Compute/diskAccesses'] : {} 
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${diskAccessName}'
  location: location
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
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
