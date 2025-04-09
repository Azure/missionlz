using './solution.bicep'

param vgwName = 'cln-vgw-hub-va-dev'
param vgwLocation = 'usgovvirginia'
param vgwPublicIpAddressNames = [
  'cln-pip-vgw-hub-dev-va-1'
  'cln-pip-vgw-hub-dev-va-2'
]
param vgwSku = 'VpnGw2'
param sharedKey = ''
param localNetworkGatewayName = 'cln-lng-hub-va-dev'
param localGatewayIpAddress = '20.158.211.83'
param allowedAzureAddressPrefixes = [
  '10.0.130.0/24'
  '10.0.131.0/24'
  '10.0.132.0/24'
  '10.0.128.0/23'
]
param localAddressPrefixes = ['10.1.0.0/16']
param useSharedKey = true
param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/cln-rg-hub-network-va-dev/providers/Microsoft.Network/virtualNetworks/cln-vnet-hub-va-dev'
param vnetResourceIdList = [
  '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/cln-0-rg-avd-network-va-dev/providers/Microsoft.Network/virtualNetworks/cln-0-vnet-avd-va-dev'
  '/subscriptions/d9cb6670-f9bf-416f-aa7b-2d6936edcaeb/resourceGroups/cln-rg-identity-network-va-dev/providers/Microsoft.Network/virtualNetworks/cln-vnet-identity-va-dev'
  '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/cln-rg-operations-network-va-dev/providers/Microsoft.Network/virtualNetworks/cln-vnet-operations-va-dev'
  '/subscriptions/3a8f043c-c15c-4a67-9410-a585a85f2109/resourceGroups/cln-rg-sharedServices-network-va-dev/providers/Microsoft.Network/virtualNetworks/cln-vnet-sharedServices-va-dev'
]
param azureFirewallResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/cln-rg-hub-network-va-dev/providers/Microsoft.Network/firewallPolicies/cln-afwp-hub-va-dev'
param vgwRouteTableName = 'cln-vgw-rt-hub-va-dev'
param gatewaySubnetName = 'GatewaySubnet'
param hubVnetRouteTableResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/cln-rg-hub-network-va-dev/providers/Microsoft.Network/virtualNetworks/cln-vnet-hub-va-dev'
param firewallRuleCollectionGroups = [
  {
    name: 'VGW-NetworkCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          name: 'AllowAllTraffic'
          priority: 150
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowAzureToOnPrem'
              ruleType: 'NetworkRule'
              ipProtocols: ['Any']
              sourceAddresses: [localAddressPrefixes]
              destinationAddresses: [allowedAzureAddressPrefixes]
              destinationPorts: ['*']
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: []
            }
            {
              name: 'AllowOnPremToAzure'
              ruleType: 'NetworkRule'
              ipProtocols: ['Any']
              sourceAddresses: [allowedAzureAddressPrefixes]
              destinationAddresses: [localAddressPrefixes]
              destinationPorts: ['*']
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: []
            }
          ]
        }
      ]
    }
  }
]

