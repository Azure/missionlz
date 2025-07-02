param name string
param tags object

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: name
  location: 'global'
  tags: tags
}

output resourceId string = privateDnsZone.id
