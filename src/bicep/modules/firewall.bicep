/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/


param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Standard'
  'Premium'
])
param skuTier string

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param threatIntelMode string

@allowed([
  'Alert'
  'Deny'
  'Off'
])
param intrusionDetectionMode string

//DNS Proxy Settings
param enableProxy bool
param dnsServers array

param clientIpConfigurationName string
param clientIpConfigurationSubnetResourceId string
param clientIpConfigurationPublicIPAddressResourceId string

param managementIpConfigurationName string
param managementIpConfigurationSubnetResourceId string
param managementIpConfigurationPublicIPAddressResourceId string

param firewallPolicyName string

param firewallSupernetIPAddress string

param logStorageAccountResourceId string
param logAnalyticsWorkspaceResourceId string

param logs array
param metrics array

var intrusionDetectionObject = {
  mode: intrusionDetectionMode
}


resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: firewallPolicyName
  location: location
  tags: tags
  properties: {
    threatIntelMode: threatIntelMode
    intrusionDetection: ((skuTier == 'Premium') ? intrusionDetectionObject : null)
    sku: {
      tier: skuTier
    }
    dnsSettings: {
      enableProxy: enableProxy
      servers: dnsServers
    }
  }
}

resource firewallAppRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-02-01' = {
  name: '${firewallPolicyName}/DefaultApplicationRuleCollectionGroup'
  dependsOn: [
    firewallPolicy
  ]
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'msftauth'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              'aadcdn.msftauth.net'
              'aadcdn.msauth.net'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: []
            sourceIpGroups: []
          }
        ]
        name: 'AzureAuth'
        priority: 110
      }
    ]
  }
}

resource firewallNetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-02-01' = {
  name: '${firewallPolicyName}/DefaultNetworkRuleCollectionGroup'
  dependsOn: [
    firewallPolicy
    firewallAppRuleCollectionGroup
  ]
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AzureCloud'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              'AzureCloud'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: 'AllowAzureCloud'
        priority: 100
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllSpokeTraffic'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              firewallSupernetIPAddress
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: 'AllowTrafficBetweenSpokes'
        priority: 200
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
  name: name
  location: location
  tags: tags
  dependsOn: [
    firewallNetworkRuleCollectionGroup
    firewallAppRuleCollectionGroup
  ]
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

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: firewall
  name: '${firewall.name}-diagnostics'
  properties: {
    storageAccountId: logStorageAccountResourceId
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: logs
    metrics: metrics
  }
}

output privateIPAddress string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
