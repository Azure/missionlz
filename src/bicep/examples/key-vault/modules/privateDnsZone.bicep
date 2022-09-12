@description('The name of the private dns zone')
param privateDnsZoneName string

@description('Array of virtual networks to connect the private dns zone to, containing properties name and resourceId')
param virtualNetworks array

@description('The tags that will be associated to the resources')
param tags object

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

resource privateDnsZoneVnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01'= [for vnet in virtualNetworks: {
  name: '${privateDnsZoneName}/${vnet.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.resourceId
    }
  }
  dependsOn: [
    privateDnsZone
  ]
}]

output privateDnsZoneResourceId string = privateDnsZone.id
