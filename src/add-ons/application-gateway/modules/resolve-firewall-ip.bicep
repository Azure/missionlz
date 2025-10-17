// resolve-firewall-ip.bicep
// RG-scoped helper to retrieve Azure Firewall private IP without exposing runtime properties at subscription template level.

targetScope = 'resourceGroup'

@description('Name of the Azure Firewall.')
param firewallName string

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-11-01' existing = {
  name: firewallName
}

// Simpler approach: rely on first ipConfiguration (platform standard for single configuration); fallback to empty string if structure unexpected.
var privateIp = (length(azureFirewall.properties.ipConfigurations) > 0 && !empty(azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress)) ? azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress : ''

output privateIpAddress string = string(privateIp)
