/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param groupIds array
param location string
param mlzTags object
param name string
param networkInterfaceName string
param privateDnsZoneConfigs array
param privateLinkServiceId string
param subnetResourceId string
param tags object

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Network/privateEndpoints'] ?? {}, mlzTags)
  properties: {
    customNetworkInterfaceName: networkInterfaceName
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: name
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: privateDnsZoneConfigs
  }
}

output networkInterfaceResourceId string = privateEndpoint.properties.networkInterfaces[0].id
