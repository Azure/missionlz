// Assume hubVnetAddressSpace is a parameter or variable from another part of your script
@description('Address space prefixes of the virtual network')
param hubVnetAddressSpace array

@description('Private IP address of the Azure Firewall')
param firewallPrivateIp string

// Create a variable with the route definitions
output routes array = [
  for i in range(0, length(hubVnetAddressSpace)): {
    name: 'onpremtomlz-${i}' // Ensure unique route names
    addressPrefix: hubVnetAddressSpace[i]
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: firewallPrivateIp
  }
]


