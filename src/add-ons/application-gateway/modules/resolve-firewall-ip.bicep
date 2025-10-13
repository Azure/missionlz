// resolve-firewall-ip.bicep
// RG-scoped helper to retrieve Azure Firewall private IP without exposing runtime properties at subscription template level.

targetScope = 'resourceGroup'

@description('Name of the Azure Firewall.')
param firewallName string

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-11-01' existing = {
  name: firewallName
}

// ipConfigurations array first element private IP (assuming standard single IP config pattern)
var privateIp = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress

output privateIpAddress string = privateIp
