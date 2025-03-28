using './solution.bicep'

param additionalSubnets = []
param deployActivityLogDiagnosticSetting = true
param deployDefender = true
param deployNetworkWatcherTrafficAnalytics = true
param deployPolicy = true
param emailSecurityContact = 'brsteel@microsoft.com'
param environmentAbbreviation = 'dev'
param firewallResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/firew-rg-hub-network-va-dev/providers/Microsoft.Network/azureFirewalls/firew-afw-hub-va-dev'
param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/firew-rg-hub-network-va-dev/providers/Microsoft.Network/virtualNetworks/firew-vnet-hub-va-dev'
param identifier = 'fw'
param keyVaultDiagnosticLogs = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]
param keyVaultDiagnosticMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]
param logAnalyticsWorkspaceResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/firew-rg-operations-network-va-dev/providers/Microsoft.OperationalInsights/workspaces/firew-log-operations-va-dev'
param logStorageSkuName = 'Standard_GRS'
param networkInterfaceDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]
param networkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]
param networkSecurityGroupRules = []
param networkWatcherFlowLogsRetentionDays = 30
param networkWatcherFlowLogsType = 'VirtualNetwork'
param networkWatcherResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/firew-rg-hub-network-va-dev/providers/Microsoft.Network/networkWatchers/firew-nw-hub-va-dev'
param policy = 'NISTRev4'
param stampIndex = '0'
param subnetAddressPrefix = '10.0.133.0/24'
param subnetName = 'default'
param tags = {}
param virtualNetworkAddressPrefix = '10.0.133.0/24'
param virtualNetworkDiagnosticsLogs = [
  {
    category: 'VMProtectionAlerts'
    enabled: true
  }
]
param virtualNetworkDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]
param windowsAdministratorsGroupMembership = 'xadmin'
param workloadName = 'tier3'
param workloadShortName = 't3'
param operationsVirtualNetworkAddressPrefix = '10.0.131.0/24'
param firewallRuleCollectionGroups = [
  {
    name: 'tier3NetworkCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          name: 'Tier3-AllowMonitorToLAW'
          priority: 150
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AllowMonitorToLAW'
              ruleType: 'NetworkRule'
              ipProtocols: ['Tcp']
              sourceAddresses: [virtualNetworkAddressPrefix]
              destinationAddresses: [cidrHost(operationsVirtualNetworkAddressPrefix, 3)] // Network of the Log Analytics Workspace, could be narrowed using parameters file post deployment
              destinationPorts: ['443'] // HTTPS port for Azure Monitor
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

