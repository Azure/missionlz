param applicationGatewayPrivateIPAddress string
param externalDnsHostname string
param hubVirtualNetworkId string
param resourcePrefix string
param virtualNetworkId string


var privateDNSZoneName ='${split(externalDnsHostname, '.')[1]}.${split(externalDnsHostname, '.')[2]}'
var aRecordName = split(externalDnsHostname, '.')[0]

resource privatezone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  properties: {}
}

resource esriLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatezone
  name: '${resourcePrefix}-esri-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: true
   }
}

resource hubLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatezone
  name: '${resourcePrefix}-hub-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: hubVirtualNetworkId
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

output privateDNSZoneName string = privateDNSZoneName
