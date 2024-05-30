/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param location string
param mlzTags object = {}
param name string
param networkSecurityGroupResourceId string
param privateIPAddressAllocationMethod string
param subnetResourceId string
param tags object = {}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}, mlzTags)
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnetResourceId
          }
          privateIPAllocationMethod: privateIPAddressAllocationMethod
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
