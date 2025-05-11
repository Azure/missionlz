param azureBlobsPrivateDnsZoneResourceId string
param delimiter string
param hostPoolResourceId string
param location string
param mlzTags object
param names object
param stampIndexFull string
param subnetResourceId string
param tags object

var diskAccessName = replace(names.diskAccess, '${delimiter}${stampIndexFull}', '')
var diskAccessNetworkInterface = replace(names.diskAccessNetworkInterface, '${delimiter}${stampIndexFull}', '')
var diskAccessPrivateEndpointName = replace(names.diskAccessPrivateEndpoint, '${delimiter}${stampIndexFull}', '')

resource diskAccess 'Microsoft.Compute/diskAccesses@2021-04-01' = {
  name: diskAccessName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Compute/diskAccesses'] ?? {}, mlzTags)
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: diskAccessPrivateEndpointName
  location: location
  tags: union({'cm-resource-parent': hostPoolResourceId}, tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: diskAccessNetworkInterface
    privateLinkServiceConnections: [
      {
        name: diskAccessPrivateEndpointName
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
  name: diskAccessName
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
