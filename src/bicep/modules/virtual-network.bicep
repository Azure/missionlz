/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param addressPrefix string
param location string
param mlzTags object
param name string
param subnets array
param tags object
param vNetDnsServers array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Network/virtualNetworks'] ?? {}, mlzTags)
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
    dhcpOptions: empty(vNetDnsServers) ? null : {
      dnsServers: vNetDnsServers
    }
  }
}

output addressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
output dnsServers array = vNetDnsServers
output id string = virtualNetwork.id
output name string = virtualNetwork.name
output subnets array = virtualNetwork.properties.subnets
