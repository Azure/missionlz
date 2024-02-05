/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param addressPrefix string
param location string
param name string
param subnets array
param tags object
param vNetDnsServers array
param firewallSkuTier string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: subnets
    dhcpOptions: (vNetDnsServers != null && (firewallSkuTier == 'Premium' || firewallSkuTier == 'Standard'))  ? {
      dnsServers: vNetDnsServers
    } : null
  }
}

output name string = virtualNetwork.name
output id string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
output addressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
