param azureFirewallResourceId string

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-11-01' existing = {
  name: split(azureFirewallResourceId, '/')[8]
  scope: resourceGroup(split(azureFirewallResourceId, '/')[2], split(azureFirewallResourceId, '/')[4])
}

output name string = split(azureFirewall.properties.firewallPolicy.id, '/')[8]
