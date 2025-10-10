using './solution.bicep'

// Updated for new-dev environment (October 2025) – MLZ forced tunneling variant
// hub vnet id from last successful MLZ deployment outputs
param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/new-dev-va-hub-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-hub-vnet'

// Operations Log Analytics workspace (destination for diagnostics)
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/new-dev-va-operations-rg-network/providers/Microsoft.OperationalInsights/workspaces/new-dev-va-operations-log'

// List of spoke VNets (identity, operations, sharedServices) that will use the VPN Gateway
// NOTE: Do not include the hub VNet itself here.
param virtualNetworkResourceIdList = [
  '/subscriptions/d9cb6670-f9bf-416f-aa7b-2d6936edcaeb/resourceGroups/new-dev-va-identity-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-identity-vnet'
  '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/new-dev-va-operations-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-operations-vnet'
  '/subscriptions/3a8f043c-c15c-4a67-9410-a585a85f2109/resourceGroups/new-dev-va-sharedServices-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-sharedServices-vnet'
]

// On-prem (simulated) address prefixes reachable via the Local Network Gateway.
// TODO: Replace the placeholder if the test on-prem gateway uses a different address space.
// Simulated on-prem address prefixes (discovered from test-onprem-vnet addressSpace)
param localAddressPrefixes = [
  '10.1.0.0/16'
  '10.2.0.0/16'
]

// Public IP of the existing test VPN gateway acting as "on-prem" (primary PIP chosen from list: 20.158.211.83, 20.158.211.81)
// If active-active is intended, only one PIP is needed for Local Network Gateway; choose the currently active/primary.
param localGatewayIpAddress = '20.158.211.83'

// (includeHubOnPrem parameter removed from solution.bicep – do not re-add)

