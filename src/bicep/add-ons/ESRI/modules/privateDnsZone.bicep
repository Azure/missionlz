param externalDnsHostname string
param virtualNetworkId string
param applicationGatewayPrivateIPAddress string

var privateDNSZoneName ='${split(externalDnsHostname, '.')[1]}.${split(externalDnsHostname, '.')[2]}'
var aRecordName = split(externalDnsHostname, '.')[0]

resource privatezone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  properties: {}
}

resource vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatezone
  name: 'vnetLink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: false
   }
}

resource webrecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: privatezone
  name: aRecordName
  properties: {
    ttl: 3600
    aRecords: [
      {
        #disable-next-line BCP053
        ipv4Address: applicationGatewayPrivateIPAddress
      }
    ]
  }
}
