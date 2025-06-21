/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param mlzTags object = {}
param name string
param networkSecurityGroupResourceId string
param privateIPAddress string = ''
param subnetResourceId string
param tags object = {}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Network/networkInterfaces'] ?? {}, mlzTags)
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAddress: empty(privateIPAddress) ? null : privateIPAddress
          privateIPAllocationMethod: empty(privateIPAddress) ? 'Dynamic' : 'Static'
          subnet: {
            id: subnetResourceId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupResourceId
    }
  }
}

output id string = networkInterface.id
output name string = networkInterface.name
