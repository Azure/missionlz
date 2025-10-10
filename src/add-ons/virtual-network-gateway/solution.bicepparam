using './solution.bicep'

param hubVirtualNetworkResourceId = '/subscriptions/6acb75ac-813c-4d62-950e-ad9d5813323a/resourceGroups/cae-dev-az-hub-rg-network/providers/Microsoft.Network/virtualNetworks/cae-dev-az-hub-vnet'
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/5c42ee82-0380-49ce-a0d6-b19392c6d34f/resourceGroups/cae-dev-az-operations-rg-network/providers/Microsoft.OperationalInsights/workspaces/cae-dev-az-operations-log'
param virtualNetworkResourceIdList = [
  '/subscriptions/75d88fa1-14cd-4793-86d7-b1b80782cfbc/resourceGroups/cae-dev-az-identity-rg-network/providers/Microsoft.Network/virtualNetworks/cae-dev-az-identity-vnet'
  '/subscriptions/5c42ee82-0380-49ce-a0d6-b19392c6d34f/resourceGroups/cae-dev-az-operations-rg-network/providers/Microsoft.Network/virtualNetworks/cae-dev-az-operations-vnet'
  '/subscriptions/380bdcb6-d99e-41f3-9803-12765826688a/resourceGroups/cae-dev-az-sharedServices-rg-network/providers/Microsoft.Network/virtualNetworks/cae-dev-az-sharedServices-vnet'
  '/subscriptions/58cc8f35-81c0-4aa1-9306-fa9ae7698767/resourceGroups/cae-dev-az-avd-rg-network/providers/Microsoft.Network/virtualNetworks/cae-dev-az-avd-vnet'
]
param localAddressPrefixes = [
  '10.1.0.0/16'
]
param localGatewayIpAddress = '20.158.211.83'
param includeHubOnPrem = true

