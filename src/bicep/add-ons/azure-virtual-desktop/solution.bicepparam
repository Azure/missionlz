using './solution.bicep'

param activeDirectorySolution = 'MicrosoftEntraId'
param availability = 'AvailabilityZones'
param availabilityZones = [
  '1'
  '2'
  '3'
]
param avdConfigurationZipFileName = 'Configuration_1.0.02790.438.zip'
param avdObjectId = 'b4e1db8e-554e-46e7-b594-2410d928f601'
param deployActivityLogDiagnosticSetting = true
param deployDefender = true
param deployNetworkWatcherTrafficAnalytics = true
param deployPolicy = true
param desktopFriendlyName = 'desktop'
param diskSku = 'Premium_LRS'
param emailSecurityContact = 'brsteel@microsoft.com'
param enableAcceleratedNetworking = true
param enableApplicationInsights = true
param enableAvdInsights = true
param enableTelemetry = true
param environmentAbbreviation = 'dev'
param existingSharedActiveDirectoryConnection = false
param hostPoolPublicNetworkAccess = 'Enabled'
param hostPoolType = 'Pooled'
param hubAzureFirewallResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/firew-rg-hub-network-va-dev/providers/Microsoft.Network/azureFirewalls/firew-afw-hub-va-dev'
param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/firew-rg-hub-network-va-dev/providers/Microsoft.Network/virtualNetworks/firew-vnet-hub-va-dev'
param identifier = 'fw'
param imageOffer = 'office-365'
param imagePublisher = 'MicrosoftWindowsDesktop'
param imageSku = 'win11-22h2-avd-m365'
param keyVaultDiagnosticsLogs = [
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
param logAnalyticsWorkspaceRetention = 30
param logAnalyticsWorkspaceSku = 'PerGB2018'
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
param networkWatcherFlowLogsRetentionDays = 30
param networkWatcherFlowLogsType = 'VirtualNetwork'
param networkWatcherResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/firew-rg-hub-network-va-dev/providers/Microsoft.Network/networkWatchers/firew-nw-hub-va-dev'
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/firew-rg-operations-network-va-dev/providers/Microsoft.OperationalInsights/workspaces/firew-log-operations-va-dev'
param policy = 'NISTRev4'
param profile = 'Generic'
param sessionHostCount = 3
param sessionHostIndex = 0
param sharedServicesSubnetResourceId = '/subscriptions/3a8f043c-c15c-4a67-9410-a585a85f2109/resourceGroups/firew-rg-sharedServices-network-va-dev/providers/Microsoft.Network/virtualNetworks/firew-vnet-sharedServices-va-dev/subnets/firew-snet-sharedServices-va-dev'
param validationEnvironment = false
param virtualMachineAdminUsername = 'xadmin'
param virtualMachineAdminPassword = ''
param securityPrincipals = [
  {
    displayName: 'brsteel-avd-users'
    objectId: '07fbc372-4ad5-4bbb-847e-b19366b6bf9d'
  }
]
param privateLinkScopeResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/firew-rg-operations-network-va-dev/providers/microsoft.insights/privateLinkScopes/firew-pls-operations-va-dev'
param virtualMachineVirtualCpuCount = 2
param workspaceFriendlyName = 'workspace'
param workspacePublicNetworkAccess = 'Enabled'
param virtualNetworkAddressPrefixes = [
  '10.0.140.0/23'
]
param identityVirtualNetworkAddressPrefix = '10.0.130.0/24'
param firewallRuleCollectionGroups = concat(
  [ 
    {
      name: 'AVD-ApplicationCollectionGroup'
      properties: {
        priority: 300
        ruleCollections: [
          {
            name: 'AVD-Endpoints'
            priority: 110
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            action: {
              type: 'Allow'
            }
            rules: [
              {
                name: 'AVDManagementEndpoints'
                ruleType: 'ApplicationRule'
                protocols: [
                  {
                    protocolType: 'Https'
                    port: 443
                  }
                ]
                fqdnTags: []
                webCategories: []
                targetFqdns: [
                  '*.microsoftonline.us'
                  '*.wvd.microsoftonline.us'
                  '*.microsoftonline.us'
                  '*.graph.microsoft.us'
                  '*.aadcdn.msftauth.net'
                  '*.aadcdn.msauth.net'
                  'enterpriseregistration.windows.net'
                ]
                targetUrls: []
                terminateTLS: false
                sourceAddresses: virtualNetworkAddressPrefixes
                destinationAddresses: []
                sourceIpGroups: []
              }
            ]
          }
        ]
      }
    }
  ],
  // Conditionally add the IdentityCommunicationCollectionGroup
  contains(activeDirectorySolution, 'DomainServices') ? [
    {
      name: 'IdentityCommunicationCollectionGroup'
      properties: {
        priority: 310
        ruleCollections: [
          {
            name: 'IdentityCommunication'
            priority: 120
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            action: {
              type: 'Allow'
            }
            rules: [
              {
                name: 'IdentityCommunicationRule'
                ruleType: 'NetworkRule'
                protocols: [
                  {
                    protocolType: 'Tcp'
                    port: 53
                  }
                  {
                    protocolType: 'Udp'
                    port: 53
                  }
                  {
                    protocolType: 'Tcp'
                    port: 88
                  }
                  {
                    protocolType: 'Tcp'
                    port: 389
                  }
                  {
                    protocolType: 'Udp'
                    port: 389
                  }
                  {
                    protocolType: 'Tcp'
                    port: 445
                  }
                  {
                    protocolType: 'Tcp'
                    port: 139
                  }
                  {
                    protocolType: 'Tcp'
                    port: 135
                  }
                  {
                    protocolType: 'Tcp'
                    port: 89
                  }
                  {
                    protocolType: 'Tcp'
                    startport: 49512
                    endport: 65535
                  }
                ]
                sourceAddresses: virtualNetworkAddressPrefixes
                destinationAddresses: [
                  identityVirtualNetworkAddressPrefix
                ]
                sourceIpGroups: []
              }
            ]
          }
        ]
      }
    }
  ] : [] 
)
