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
  'Standard'
  'Premium'
  'Basic'
])
param skuTier string
param tags object = {}
@allowed([
  'Alert'
  'Deny'
  'Off'
])
param threatIntelMode string

var intrusionDetectionObject = {
  mode: intrusionDetectionMode
}

var dnsSettings = {
  enableProxy: enableProxy
  servers: dnsServers
}

// Load the JSON file containing the rule collections (hardcoded relative path)
var ruleCollectionsConfig = json(loadTextContent('./firewall-rules.json'))

// Check if the JSON file contains valid data for ruleCollectionsConfig
var hasValidRuleCollectionsConfig = contains(ruleCollectionsConfig, 'name') && contains(ruleCollectionsConfig, 'priority') && contains(ruleCollectionsConfig, 'priority') && contains(ruleCollectionsConfig, 'ruleCollections') && !empty(ruleCollectionsConfig.name)

// Define the firewall policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: firewallPolicyName
  location: location
  tags: union(tags[?'Microsoft.Network/firewallPolicies'] ?? {}, mlzTags)
  properties: {
    threatIntelMode: threatIntelMode
    intrusionDetection: ((skuTier == 'Premium') ? intrusionDetectionObject : null)
    sku: {
      tier: skuTier
    }
    dnsSettings: ((skuTier == 'Premium' || skuTier == 'Standard') ? dnsSettings : null)
  }
}


// Loop through collection groups and create resources dynamically without internal sequential dependencies
resource firewallCollectionGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-02-01' = if (hasValidRuleCollectionsConfig) {
  parent: firewallPolicy
  name: ruleCollectionsConfig.name
  properties: {
    priority: ruleCollectionsConfig.priority
    ruleCollections: ruleCollectionsConfig.ruleCollections
  }
}

// Define the Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: name
  location: location
  tags: union(tags[?'Microsoft.Network/azureFirewalls'] ?? {}, mlzTags)
  dependsOn: [
    firewallCollectionGroups
  ]
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
