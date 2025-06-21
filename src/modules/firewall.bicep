/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param clientIpConfigurationSubnetResourceId string
param clientIpConfigurationPublicIPAddressResourceId string
param dnsServers array
param enableProxy bool
param firewallPolicyName string

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param intrusionDetectionMode string
param location string
param managementIpConfigurationSubnetResourceId string
param managementIpConfigurationPublicIPAddressResourceId string
param mlzTags object
param name string
@allowed([
  'Premium'
  'Standard'
])
param skuTier string
param tags object = {}
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param threatIntelMode string
param firewallRuleCollectionGroups array

var intrusionDetectionObject = {
  mode: intrusionDetectionMode
}

var dnsSettings = {
  enableProxy: enableProxy
  servers: dnsServers
}


// Define the firewall policy
@description('Azure Firewall Policy')
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: firewallPolicyName
  location: location
  tags: union(tags[?'Microsoft.Network/firewallPolicies'] ?? {}, mlzTags)
  properties: {
    threatIntelMode: threatIntelMode
    intrusionDetection: skuTier == 'Premium' ? intrusionDetectionObject : null
    sku: {
      tier: skuTier
    }
    dnsSettings: dnsSettings
  }
}

module defaultRuleCollectionsConfig './firewall-rules.bicep' = {
    name: 'defaultRuleCollectionsConfig'
    scope: resourceGroup(split(firewallPolicy.id, '/')[2], split(firewallPolicy.id, '/')[4])
  params: {
    firewallPolicyName: firewallPolicy.name
    firewallRuleCollectionGroups: firewallRuleCollectionGroups
  }
  dependsOn: [
    firewall
  ]
}

// Define the Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Network/azureFirewalls'] ?? {}, mlzTags)
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-client'
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
      name: 'ipconfig-management'
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

// Outputs
output name string = firewall.name
output privateIPAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output resourceId string = firewall.id
