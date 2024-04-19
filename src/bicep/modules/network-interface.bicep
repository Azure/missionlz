/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param ipConfigurationName string
param location string
param mlzTags object = {}
param name string
param networkSecurityGroupId string
param privateIPAddressAllocationMethod string
param subnetId string
param tags object = {}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}, mlzTags)
  properties: {
    ipConfigurations: [
      {
        name: ipConfigurationName
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: privateIPAddressAllocationMethod
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroupId
    }
  }
}

output id string = networkInterface.id
output name string = networkInterface.name
