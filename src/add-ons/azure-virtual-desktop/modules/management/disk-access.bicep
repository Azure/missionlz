param azureBlobsPrivateDnsZoneResourceId string
param hostPoolResourceId string
param location string
param mlzTags object
param names object
param subnetResourceId string
param tags object
param tokens object

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: replace(names.diskAccess, tokens.purpose, '')
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/diskAccesses'] ?? {}, mlzTags)
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: replace(names.diskAccessPrivateEndpoint, tokens.purpose, '')
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: replace(names.diskAccessNetworkInterface, tokens.purpose, '')
    privateLinkServiceConnections: [
      {
        name: replace(names.diskAccessPrivateEndpoint, tokens.purpose, '')
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
