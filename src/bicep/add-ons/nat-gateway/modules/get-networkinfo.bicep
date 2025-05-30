@description('Resource ID of the hub firewall. Used to derive VNet and subnet info.')
param hubFirewallResourceId string

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' existing = {
  name: split(hubFirewallResourceId, '/')[8]
}

var firewallSubnetId = firewall.properties.ipConfigurations[0].properties.subnet.id
var firewallVnetName = split(firewallSubnetId, '/')[8]
var firewallSubnetName = 'AzureFirewallSubnet'

module getSubnetAddressPrefix './get-subnetaddressprefix.bicep' = {
  name: 'getSubnetAddressPrefix'
  params: {
    vnetName: firewallVnetName
    subnetName: firewallSubnetName
  }
}

output vnetName string = firewallVnetName
output subnetName string = firewallSubnetName
output addressPrefix string = getSubnetAddressPrefix.outputs.addressPrefix
