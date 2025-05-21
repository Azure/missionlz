param name string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: name
}

output location string = virtualNetwork.location
