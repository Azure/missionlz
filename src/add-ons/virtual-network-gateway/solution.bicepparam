using './solution.bicep'

param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/mlz-dev-va-hub-rg-network/providers/Microsoft.Network/virtualNetworks/mlz-dev-va-hub-vnet'
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/mlz-dev-va-operations-rg-network/providers/Microsoft.OperationalInsights/workspaces/mlz-dev-va-operations-log'
param virtualNetworkResourceIdList = [
  '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/mlz-dev-va-operations-rg-network/providers/Microsoft.Network/virtualNetworks/mlz-dev-va-operations-vnet'
  '/subscriptions/3a8f043c-c15c-4a67-9410-a585a85f2109/resourceGroups/mlz-dev-va-sharedServices-rg-network/providers/Microsoft.Network/virtualNetworks/mlz-dev-va-sharedServices-vnet'
  '/subscriptions/d9cb6670-f9bf-416f-aa7b-2d6936edcaeb/resourceGroups/mlz-dev-va-identity-rg-network/providers/Microsoft.Network/virtualNetworks/mlz-dev-va-identity-vnet'
]
param localAddressPrefixes = [
  '10.1.0.0/16'
]
param localGatewayIpAddress = '20.158.211.83'
param sharedKey = ''
param virtualNetworkGatewaySku = 'VpnGw2'
param customFirewallRuleCollectionGroups = []
param includeHubOnPrem = false

