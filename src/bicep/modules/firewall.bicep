param name string
param location string = resourceGroup().location
param tags object = {}

param skuTier string
param threatIntelMode string

param clientIpConfigurationName string
param clientIpConfigurationSubnetResourceId string
param clientIpConfigurationPublicIPAddressResourceId string

param managementIpConfigurationName string
param managementIpConfigurationSubnetResourceId string
param managementIpConfigurationPublicIPAddressResourceId string

param firewallPolicyName string

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: firewallPolicyName
  location: location
  tags: tags
  properties: {
    threatIntelMode: threatIntelMode
    sku: {
      tier: skuTier
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: name
  location: location
  tags: tags

  properties: {
    ipConfigurations: [
      {
        name: clientIpConfigurationName
        properties: {
          subnet: {
            id: clientIpConfigurationSubnetResourceId
          }
          publicIPAddress: {
            id: clientIpConfigurationPublicIPAddressResourceId
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: managementIpConfigurationName
      properties: {
        subnet: {
          id: managementIpConfigurationSubnetResourceId
        }
        publicIPAddress: {
          id: managementIpConfigurationPublicIPAddressResourceId
        }
      }
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    sku: {
      tier: skuTier
    }
  }
}

output privateIPAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
