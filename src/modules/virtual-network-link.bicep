/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param privateDnsZoneNames array
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkSubscriptionId string

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' existing = [for (name, i) in privateDnsZoneNames: {
  name: name
}]

resource virtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = [for (name, i) in privateDnsZoneNames: {
  name: virtualNetworkName
  parent: privateDnsZones[i]
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(virtualNetworkSubscriptionId, virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
  }
}]
