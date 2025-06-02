using './solution.bicep'

param natGatewayDeployments = [
  {
    subnetResourceId: '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/new-dev-va-hub-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-hub-vnet/subnets/AzureFirewallSubnet'
    zone: '1'
    tcpIdleTimeout: 10
    publicIpPrefixLength: 30
  }
  {
    subnetResourceId: '/subscriptions/d9cb6670-f9bf-416f-aa7b-2d6936edcaeb/resourceGroups/new-dev-va-identity-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-identity-vnet/subnets/new-dev-va-identity-snet'
    zone: ''
    tcpIdleTimeout: 4
    publicIpPrefixLength: 30
  }
]


