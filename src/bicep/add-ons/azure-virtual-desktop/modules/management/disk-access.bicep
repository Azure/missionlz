param azureBlobsPrivateDnsZoneResourceId string
param hostPoolResourceId string
param location string
param mlzTags object
param namingConvention object
param subnetResourceId string
param tags object

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: namingConvention.diskAccess
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/diskAccesses'] ?? {}, mlzTags)
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: namingConvention.diskAccessPrivateEndpoint
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
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

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: namingConvention.diskAccess
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: azureBlobsPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

output resourceId string = diskAccess.id
