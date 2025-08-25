using './solution.bicep'

param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/mlz-dev-va-hub-rg-network/providers/Microsoft.Network/virtualNetworks/mlz-dev-va-hub-vnet'
param zone = '1'
param tcpIdleTimeout = 4
param publicIpPrefixLength = 30
