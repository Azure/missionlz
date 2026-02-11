using './solution.bicep'

param environmentAbbreviation = 'dev'
param hubVirtualNetworkResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/<resource-group-name>/providers/Microsoft.Network/virtualNetworks/<virtual-network-name>'
param identifier = 'mlz'
param publicIpPrefixLength = 30
param tcpIdleTimeout = 4
param zone = '1'
