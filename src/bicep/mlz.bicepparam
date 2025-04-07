using 'mlz.bicep'

param deployAzureGatewaySubnet = true
param deployBastion = true
param deployDefender = true
param deployDefenderPlans = [
  'VirtualMachines'
]
param deployIdentity = true
param deployNetworkWatcherTrafficAnalytics = true
param deployPolicy = true
param deploySentinel = true
param deployWindowsVirtualMachine = true
param emailSecurityContact = 'brooke.steele@microsoft.com'
param hubSubscriptionId = 'afb59830-1fc9-44c9-bba3-04f657483578'
param hybridUseBenefit = true
param identitySubscriptionId = 'd9cb6670-f9bf-416f-aa7b-2d6936edcaeb'
param location = 'usgovvirginia'
param operationsSubscriptionId = '6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24'
param policy = 'NISTRev5'
param resourcePrefix = 'cln'
param sharedServicesSubscriptionId = '3a8f043c-c15c-4a67-9410-a585a85f2109'
param windowsVmAdminUsername = 'xadmin'
param windowsVmCreateOption = 'FromImage'
param windowsVmImageOffer = 'WindowsServer'
param windowsVmImagePublisher = 'MicrosoftWindowsServer'
param windowsVmImageSku = '2019-datacenter-gensecond'
param windowsVmNetworkInterfacePrivateIPAddressAllocationMethod = 'Dynamic'
param windowsVmSize = 'Standard_DS1_v2'
param windowsVmStorageAccountType = 'StandardSSD_LRS'
param windowsVmVersion = 'latest'
param operationsVirtualNetworkAddressPrefix = '10.0.131.0/24'
param identityVirtualNetworkAddressPrefix = '10.0.130.0/24'
param hubVirtualNetworkAddressPrefix = '10.0.128.0/23'
param sharedServicesVirtualNetworkAddressPrefix = '10.0.132.0/24'
param firewallRuleCollectionGroups = [
  {
    name: 'MLZ-ApplicationCollectionGroup'
    properties: {
      priority: 300
      ruleCollections: [
        {
          name: 'MLZ-AzureAuth'
          priority: 110
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'msftauth'
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
                'aadcdn.msftauth.net'
                'aadcdn.msauth.net'
              ]
              targetUrls: []
              terminateTLS: false
              sourceAddresses: concat(
                [
                  hubVirtualNetworkAddressPrefix // Hub network
                ],
                [
                  sharedServicesVirtualNetworkAddressPrefix // Shared network
                ],
                empty(identityVirtualNetworkAddressPrefix) ? [] : [identityVirtualNetworkAddressPrefix] // Include Identity network only if it has a value
              )
              destinationAddresses: []
              sourceIpGroups: []
            }
          ]
        }
      ]
    }
  }
  {
    name: 'MLZ-NetworkCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          name: 'MLZ-AllowMonitorToLAW'
          priority: 150
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'MLZ-AllowMonitorToLAW'
              ruleType: 'NetworkRule'
              ipProtocols: ['Tcp']
              sourceAddresses: concat(
                [
                  hubVirtualNetworkAddressPrefix // Hub network
                ],
                [
                  sharedServicesVirtualNetworkAddressPrefix // Shared network
                ],
                empty(identityVirtualNetworkAddressPrefix) ? [] : [identityVirtualNetworkAddressPrefix] // Include Identity network only if it has a value
              )
              destinationAddresses: [cidrHost(operationsVirtualNetworkAddressPrefix, 3)] // LAW private endpoint network
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

