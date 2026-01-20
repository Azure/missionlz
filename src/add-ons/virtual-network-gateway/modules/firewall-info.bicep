@description('Resource ID of the existing Azure Firewall')
param azureFirewallResourceId string

// Derive resource group and name from the resource ID
var firewallSubscriptionId = split(azureFirewallResourceId, '/')[2]
var firewallResourceGroupName = split(azureFirewallResourceId, '/')[4]
var firewallName = split(azureFirewallResourceId, '/')[8]

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-11-01' existing = {
  scope: resourceGroup(firewallSubscriptionId, firewallResourceGroupName)
  name: firewallName
}

// Direct property access is safe because resource declaration is unconditional
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPolicyId string = azureFirewall.properties.firewallPolicy.id
