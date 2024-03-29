param name string
param remoteVirtualNetworkResourceId string

resource virtualNetworkPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: name
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkResourceId
    }
  }
}
