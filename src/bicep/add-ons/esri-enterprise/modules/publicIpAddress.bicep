param hostname string
param location string
param publicIpAddressName string
param tags object
param publicIpAllocationMethod string

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIpAddressName
  location: location
  tags: tags[?'Microsoft.Network/publicIPAddresses'] ?? {}
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: publicIpAllocationMethod
    idleTimeoutInMinutes: 11
    dnsSettings: {
      domainNameLabel: hostname
      fqdn:  hostname
    }
    ipTags: []
  }
}

output pipFqdn string = publicIp.properties.dnsSettings.fqdn
output pipIp string = publicIp.properties.ipAddress
output pipId string = publicIp.id
output pipName string = publicIp.name
