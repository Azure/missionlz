/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param bastionHostSubnetResourceId string
param ipConfigurationName string
param location string
param mlzTags object
param name string
param publicIPAddressAllocationMethod string
param publicIPAddressAvailabilityZones array
param publicIPAddressName string
param publicIPAddressSkuName string
param tags object

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIPAddressName
  location: location
  tags: union(contains(tags, 'Microsoft.Network/publicIPAddresses') ? tags['Microsoft.Network/publicIPAddresses'] : {}, mlzTags)
  sku: {
    name: publicIPAddressSkuName
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressAllocationMethod
  }
  zones: publicIPAddressAvailabilityZones
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: name
  location: location
  tags: union(contains(tags, 'Microsoft.Network/bastionHosts') ? tags['Microsoft.Network/bastionHosts'] : {}, mlzTags)
  properties: {
    ipConfigurations: [
      {
        name: ipConfigurationName
        properties: {
          subnet: {
            id: bastionHostSubnetResourceId
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
  }
}
