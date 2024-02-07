param networkSecurityGroupSecurityRules array
param location string = resourceGroup().location
param networkSecurityGroupName string

resource networksecuritygroup 'Microsoft.Network/networkSecurityGroups@2020-11-01' =  {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [for item in networkSecurityGroupSecurityRules: {
      name: item.name
      properties: {
        access: item.properties.access
        destinationAddressPrefix: ((item.properties.destinationAddressPrefix == '') ? null : item.properties.destinationAddressPrefix)
        destinationAddressPrefixes: ((length(item.properties.destinationAddressPrefixes) == 0) ? null : item.properties.destinationAddressPrefixes)
        destinationPortRanges: ((length(item.properties.destinationPortRanges) == 0) ? null : item.properties.destinationPortRanges)
        destinationPortRange: ((item.properties.destinationPortRange == '') ? null : item.properties.destinationPortRange)
        direction: item.properties.direction
        priority: int(item.properties.priority)
        protocol: item.properties.protocol
        sourceAddressPrefix: ((item.properties.sourceAddressPrefix == '') ? null : item.properties.sourceAddressPrefix)
        sourcePortRanges: ((length(item.properties.sourcePortRanges) == 0) ? null : item.properties.sourcePortRanges)
        sourcePortRange: item.properties.sourcePortRange
      }
    }]
  }
}
