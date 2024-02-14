param dnsServers array
param location string = resourceGroup().location
param virtualNetworkName string
param subnets array
param udrName string
param vNetAddressPrefixes array

resource userDefinedRoute 'Microsoft.Network/routeTables@2021-05-01' existing = {
  name: udrName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vNetAddressPrefixes
    }
    dhcpOptions: !empty(dnsServers)  ? {
      dnsServers: dnsServers
    } : null
    subnets: [for item in subnets: {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
        delegations: item.delegations
        networkSecurityGroup: (empty(item.networkSecurityGroupName) ? null : json('{"id": "${resourceId('Microsoft.Network/networkSecurityGroups', item.networkSecurityGroupName)}"}'))
        privateEndpointNetworkPolicies: item.privateEndpointNetworkPolicies
        privateLinkServiceNetworkPolicies: item.privateLinkServiceNetworkPolicies
        routeTable: {
          id: userDefinedRoute.id
        }

      }
    }]
  }
}

output virtualNetworkName string = virtualNetwork.name
output virtualNetworkResourceId string = virtualNetwork.id
output subnetResourceId string = virtualNetwork.properties.subnets[0].id
