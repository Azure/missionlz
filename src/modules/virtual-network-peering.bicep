/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param remoteVirtualNetworkResourceId string
param virtualNetworkName string
param virtualNetworkPeerName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: virtualNetworkName
}

resource virtualNetworkPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  parent: virtualNetwork
  name: virtualNetworkPeerName
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkResourceId
    }
  }
}
