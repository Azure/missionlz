@description('Resource ID of the hub firewall. Used to derive VNet and subnet info.')
param hubFirewallResourceId string

@description('A suffix to use for naming deployments uniquely.')
param deploymentNameSuffix string = utcNow()

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' existing = {
  name: split(hubFirewallResourceId, '/')[8]
}

var firewallSubnetId = firewall.properties.ipConfigurations[0].properties.subnet.id
var firewallVnetName = split(firewallSubnetId, '/')[8]
var firewallSubnetName = 'AzureFirewallSubnet'

module getSubnetInfo './get-subnetinfo.bicep' = {
  name: 'getSubnetInfo-${deploymentNameSuffix}'
  params: {
    vnetName: firewallVnetName
    subnetName: firewallSubnetName
  }
}

output vnetName string = firewallVnetName
output subnetObj object = getSubnetInfo.outputs.subnet
