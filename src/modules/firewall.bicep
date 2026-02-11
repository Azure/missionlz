/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

param clientIpConfigurationSubnetResourceId string
param clientIpConfigurationPublicIPAddressResourceId string
param customPipCount int = 0
param customPublicIPAddressNamePrefix string = ''
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
param resourceGroupName string
@allowed([
  'Premium'
  'Standard'
])
param skuTier string
param subscriptionId string
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

// Build the primary IP configuration
var primaryIpConfiguration = {
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

// Build additional IP configurations for custom PIPs
var customIpConfigurations = [for i in range(1, customPipCount): {
  name: 'ipconfig-client-${i}'
  properties: {
    publicIPAddress: {
      id: resourceId(subscriptionId, resourceGroupName, 'Microsoft.Network/publicIPAddresses', '${customPublicIPAddressNamePrefix}${i}')
    }
  }
}]

// Combine all IP configurations
var allIpConfigurations = customPipCount > 0 ? union([primaryIpConfiguration], customIpConfigurations) : [primaryIpConfiguration]


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
    ipConfigurations: allIpConfigurations
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
output policyResourceId string = firewallPolicy.id
output privateIPAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output resourceId string = firewall.id
