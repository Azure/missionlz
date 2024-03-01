param applicationGatewayName string
param applicationGatewaySubnetAddressPrefix string
param location string
param resourceGroup string
param routeTableName string
param routeTableRouteNextHopIpAddress string
param tags object
param virtualNetworkAddressPrefix string
param virtualNetworkName string
param defaultSubnetAddressPrefix string
param vNetDnsServers array
param privatelink_keyvaultDns_name string
// param joinWindowsDomain bool

// module networkSecurityGroup 'network-security-group.bicep' = {
//   name: 'networkSecurityGroup'
//   params: {
//     location: location
//     name: networkSecurityGroupName
//     securityRules: networkSecurityGroupRules
//     tags: tags
//   }
// }
resource privateDnsZone_keyvaultDns 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: privatelink_keyvaultDns_name
}

module routeTable 'route-table.bicep' = {
  name: 'routeTable'
  params: {
    location: location
    name: routeTableName
    tags: tags
    routeTableNextHopIpAddress: routeTableRouteNextHopIpAddress
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: virtualNetworkName
  location: location
  tags: contains(tags, 'Microsoft.Network/virtualNetworks') ? tags['Microsoft.Network/virtualNetworks'] : {}
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    dhcpOptions: (vNetDnsServers != null) ? {
      dnsServers: vNetDnsServers
    } : null
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: defaultSubnetAddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: routeTable.outputs.id
          }
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'appGatewaySubnet'
        properties: {
          addressPrefix: applicationGatewaySubnetAddressPrefix
          applicationGatewayIPConfigurations: [
            {
              id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/gatewayIPConfigurations', applicationGatewayName, 'appGatewayIpConfig')
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: virtualNetwork
  name: 'appGatewaySubnet'
  properties: {
    addressPrefix: applicationGatewaySubnetAddressPrefix
    applicationGatewayIPConfigurations: [
      {
        id: resourceId(resourceGroup, 'Microsoft.Network/applicationGateways/gatewayIPConfigurations', applicationGatewayName, 'appGatewayIpConfig')
      }
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource defaultSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: virtualNetwork
  name: 'default'
  properties: {
    addressPrefix: defaultSubnetAddressPrefix
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    routeTable: {
      id: routeTable.outputs.id
    }
  }
}

resource keyVaultLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone_keyvaultDns
  name: '${virtualNetwork.name}-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: false
   }
}

output subnetResourceId string = defaultSubnet.id
output vNetid string = virtualNetwork.id
output vNetName string = virtualNetwork.name
output vNetAddressPrefix string = virtualNetwork.properties.addressSpace.addressPrefixes[0]
output subnetName string = defaultSubnet.name
output subnetAddressPrefix string = defaultSubnet.properties.addressPrefix
output appGatewaySubnetId string = appGatewaySubnet.id
output appGatewaySubnetName string = appGatewaySubnet.name
output appGatewaySubnetAddressPrefix string = appGatewaySubnet.properties.addressPrefix

