param functionAppName string
param ipv4Address string
param privateDnsZoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource a 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privateDnsZone
  name: functionAppName
  properties: {
    aRecords: [
      {
        ipv4Address: ipv4Address
      }
    ]
    ttl: 3600
  }
}
