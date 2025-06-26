
param privatelink_keyvaultDns_name string
param workloadVirtualNetworkName string
param virtualNetworkId string

resource privateDnsZone_keyvaultDns 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: privatelink_keyvaultDns_name
}

resource keyVaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone_keyvaultDns
  name: workloadVirtualNetworkName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: false
   }
}
