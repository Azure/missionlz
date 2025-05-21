param azureBlobsPrivateDnsZoneResourceId string
param hostPoolResourceId string
param location string
param mlzTags object
param names object
param subnetResourceId string
param tags object

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: names.diskAccess
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/diskAccesses'] ?? {}, mlzTags)
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: names.diskAccessPrivateEndpoint
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: names.diskAccessNetworkInterface
    privateLinkServiceConnections: [
      {
        name: names.diskAccessPrivateEndpoint
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
  name: diskAccess.name
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
