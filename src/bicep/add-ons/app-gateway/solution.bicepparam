using './solution.bicep'

param vnetResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/new-dev-va-hub-rg-network/providers/Microsoft.Network/virtualNetworks/new-dev-va-hub-vnet'
param subnetPrefix = '10.0.129.64/26'
param backendAddressPool = {
  name: 'myBackendPool'
  properties: {
    backendAddresses: [
      {
        ipAddress: '10.0.128.10'
      }
      {
        ipAddress: '10.0.128.11'
      }
    ]
  }
}
param frontendPrivateIpConfigs = [
  {
    name: 'frontendPrivateIp1'
    privateIPAddress: '10.0.129.68'
    privateIPAllocationMethod: 'Static'
  }
  {
    name: 'frontendPrivateIp2'
    privateIPAddress: '10.0.129.69'
    privateIPAllocationMethod: 'Static'
  }
]
param frontendPorts = [
  {
    name: 'httpPort'
    port: 80
  }
  {
    name: 'httpsPort'
    port: 443
  }
]
param webApplicationFirewallConfiguration = {
  enabled: true
  firewallMode: 'Prevention' // or 'Detection'
  ruleSetType: 'OWASP'
  ruleSetVersion: '3.2'
  // Optionally, you can add exclusions, disabledRuleGroups, etc.
  // exclusions: []
  // disabledRuleGroups: []
}
param keyvaultUri = 'https://kv3rmzihwnl7oyk.vault.azure.net'
param keyVaultCertName = 'testcert'


